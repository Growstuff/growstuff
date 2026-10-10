# frozen_string_literal: true

require 'rails_helper'

# Flickr is stubbed throughout: the dialog talks to our own JSON endpoints, and
# these stand in for what Flickr would say.
describe 'Adding a photo to a harvest', :js do
  include_context 'signed in member'

  let!(:lettuce) { create(:crop, name: 'lettuce') }
  let!(:harvest) { create(:harvest, owner: member, crop: lettuce) }
  let(:flickr_photo) { Struct.new(:id, :title, :farm, :server, :secret).new('1234', 'Cabbage', 1, '65535', 'abc123') }

  before do
    create(:flickr_authentication, member: member, name: 'Gardener')
    allow_any_instance_of(Member).to receive_messages(flickr_auth_valid?: true, flickr_sets: { 'Spring' => '77' }, # rubocop:disable RSpec/AnyInstance
                                                      flickr_photos: [[flickr_photo], 1])
    allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) do |photo| # rubocop:disable RSpec/AnyInstance
      photo.update!(title: 'Cabbage', license_name: 'CC-BY', thumbnail_url: 'http://example.com/t.jpg',
                    fullsize_url: 'http://example.com/f.jpg', link_url: 'http://example.com/p')
    end
    visit harvest_path(harvest)
  end

  it 'opens a dialog over the harvest from the actions menu' do
    click_link 'Actions'
    click_link 'Add photo'

    within '[role=dialog]' do
      expect(page).to have_content 'Add photo to lettuce harvest'
      expect(page).to have_css '.photo-picker-photo', count: 1
    end
    expect(page).to have_current_path(harvest_path(harvest))
  end

  it 'opens the same dialog from the "add" on the photos heading' do
    within('#photos .section-header') { click_link 'add' }

    within('[role=dialog]') { expect(page).to have_content 'Add photo to lettuce harvest' }
  end

  it 'adds the photo to the harvest without leaving the page' do
    within('#photos .section-header') { click_link 'add' }
    within('[role=dialog]') { find('.photo-picker-photo').click }
    within('[role=dialog]') { click_button 'Add photo' }

    # The photos section is server rendered, so saving reloads the harvest.
    expect(page).to have_no_css '[role=dialog]'
    expect(page).to have_current_path(harvest_path(harvest))
    expect(harvest.photos.reload).to contain_exactly(Photo.last)
    # The reloaded page shows it in the photos section.
    within('#photos') { expect(page).to have_css "#photo-#{Photo.last.id}" }
  end
end
