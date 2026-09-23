# frozen_string_literal: true

require 'rails_helper'

# Flickr is stubbed throughout: the dialog talks to our own JSON endpoints, and
# these stand in for what Flickr would say.
describe 'Adding a photo from a garden card', :js do
  include_context 'signed in member'

  let!(:garden) { create(:garden, owner: member, name: 'Orchard') }
  let!(:lettuce) { create(:annual_crop, name: 'lettuce') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: lettuce, planted_at: 10.days.ago) }
  let(:flickr_photo) { Struct.new(:id, :title, :farm, :server, :secret).new('1234', 'Cabbage', 1, '65535', 'abc123') }

  before do
    allow_any_instance_of(Member).to receive_messages(flickr_auth_valid?: true, flickr_sets: { 'Spring' => '77' }, # rubocop:disable RSpec/AnyInstance
                                                      flickr_photos: [[flickr_photo], 1])
    allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) do |photo| # rubocop:disable RSpec/AnyInstance
      photo.update!(title: 'Cabbage', license_name: 'CC-BY', thumbnail_url: 'http://example.com/t.jpg',
                    fullsize_url: 'http://example.com/f.jpg', link_url: 'http://example.com/p')
    end
  end

  def open_from_planting
    visit gardens_path
    within('.planting-row', text: 'lettuce') do
      click_link 'Actions for lettuce'
      click_link 'Add photo'
    end
  end

  context 'with Flickr connected' do
    before { create(:flickr_authentication, member: member, name: 'Gardener') }

    it 'opens a dialog over the list, showing your Flickr photos' do
      open_from_planting

      within '[role=dialog]' do
        expect(page).to have_content 'Add photo to lettuce planting'
        expect(page).to have_css '.plant-step-current', text: 'Choose a photo'
        expect(page).to have_content 'Connected to Flickr as Gardener'
        expect(page).to have_select 'Album', options: ['All your recent photos', 'Spring']
        expect(page).to have_css '.photo-picker-photo', count: 1
        expect(page).to have_no_content 'Connect your Flickr account'
      end
      expect(page).to have_current_path(gardens_path)
    end

    it 'confirms the choice, then adds it to the planting without leaving the list' do
      open_from_planting

      within('[role=dialog]') { find('.photo-picker-photo').click }
      within '[role=dialog]' do
        expect(page).to have_css '.plant-step-current', text: 'Confirm'
        expect(page).to have_css '.crop-confirm', text: 'lettuce'
        expect(page).to have_content 'The photo stays on Flickr'
        expect(Photo.count).to eq 0
        click_button 'Add photo'
      end

      expect(page).to have_no_css '[role=dialog]'
      expect(page).to have_content 'Added a photo to lettuce planting.'
      expect(page).to have_link 'See it', href: photo_path(Photo.last)
      expect(page).to have_current_path(gardens_path)
      expect(planting.photos.reload).to contain_exactly(Photo.last)
      expect(Photo.last).to have_attributes(owner: member, source: 'flickr', source_id: '1234')
    end

    it 'lets you go back and choose a different photo' do
      open_from_planting

      within('[role=dialog]') { find('.photo-picker-photo').click }
      within('[role=dialog]') { click_button 'Change' }

      expect(page).to have_css '.plant-step-current', text: 'Choose a photo'
      expect(page).to have_css '.photo-picker-photo'
      expect(Photo.count).to eq 0
    end

    it 'opens from the garden menu too, for the garden itself' do
      visit gardens_path
      within('.garden-card-header', text: 'Orchard') do
        click_link 'Actions for Orchard'
        click_link 'Add photo'
      end

      within '[role=dialog]' do
        expect(page).to have_content 'Add photo to Orchard garden'
        find('.photo-picker-photo').click
        click_button 'Add photo'
      end

      expect(page).to have_content 'Added a photo to Orchard garden.'
      expect(garden.photos.count).to eq 1
    end
  end

  context 'without Flickr connected' do
    it 'connects it in the dialog, in a pop-up, and carries on to choosing a photo' do
      visit gardens_path
      # The real pop-up goes to Flickr; stand in for it and note where it was sent.
      page.execute_script("window.open = function (url) { window.openedUrl = url; return {closed: false, close: function () {}}; }")
      within('.planting-row', text: 'lettuce') do
        click_link 'Actions for lettuce'
        click_link 'Add photo'
      end

      within '[role=dialog]' do
        expect(page).to have_css '.plant-step-current', text: 'Connect Flickr'
        expect(page).to have_content 'Connect your Flickr account'
        expect(page).to have_no_css '.photo-picker-photo'
        click_button 'Connect Flickr'

        expect(page).to have_content 'Waiting for you to allow access on Flickr'
      end
      expect(page.evaluate_script('window.openedUrl')).to eq "/members/auth/flickr?origin=#{ERB::Util.url_encode('/authentications/connected')}"

      create(:flickr_authentication, member: member, name: 'Gardener') # what the pop-up would have done

      within '[role=dialog]' do
        expect(page).to have_css '.plant-step-current', text: 'Choose a photo', wait: 10
        expect(page).to have_css '.plant-step-done', text: 'Connect Flickr'
        expect(page).to have_css '.photo-picker-photo', count: 1
      end
    end

    it 'says to reconnect when the connection has expired' do
      create(:flickr_authentication, member: member)
      allow_any_instance_of(Member).to receive(:flickr_auth_valid?).and_return(false) # rubocop:disable RSpec/AnyInstance

      open_from_planting

      within '[role=dialog]' do
        expect(page).to have_content 'Reconnect Flickr'
        expect(page).to have_content 'Your connection has expired'
      end
    end
  end
end
