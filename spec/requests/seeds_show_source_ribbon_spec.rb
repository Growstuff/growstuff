# frozen_string_literal: true

require 'rails_helper'

# Where a packet of seed came from, shown on its page.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed, source:) }
  let(:source) { 'my own seed saving' }
  let(:page) { Capybara.string(response.body) }

  context 'with a photo for the hero' do
    before do
      seed.photo_associations.create!(photo: create(:photo, owner: seed.owner))
      get seed_path(seed)
    end

    it('hangs the ribbon on the photo, beside its link') do
      expect(page).to have_css('.record-hero-photo-frame .seed-source-ribbon--saved', text: "Saved by #{seed.owner}")
    end

    it('does not repeat it as a badge') { expect(page).to have_no_css('.seed-source-badge') }
    it('no longer lists the source among the facts') { expect(page).to have_no_css('.packet-facts', text: 'Seed source') }

    context 'when it was bought' do
      let(:source) { 'retail outlet' }

      it('is another ribbon') { expect(page).to have_css('.record-hero-photo-frame .seed-source-ribbon--bought', text: 'Bought') }
    end

    context 'when the source is not known' do
      let(:source) { 'other/unknown' }

      it('has no ribbon') { expect(page).to have_no_css('.seed-source-ribbon') }
    end
  end

  context 'with no photo for the hero' do
    before { get seed_path(seed) }

    it('says it in a badge, among the others') do
      expect(page).to have_css('.seed-badges .seed-source-badge', text: "Saved by #{seed.owner}")
    end

    it('has no ribbon, with nothing to hang it on') { expect(page).to have_no_css('.seed-source-ribbon') }
  end

  context 'when the grower looks' do
    before do
      seed.photo_associations.create!(photo: create(:photo, owner: seed.owner))
      sign_in seed.owner
      get seed_path(seed)
    end

    it('has the ribbon as a button beside the photo, not inside its link') do
      expect(page).to have_css('.record-hero-photo-frame > .seed-source-menu button.seed-source-ribbon--saved')
    end

    it('offers the other sources') { expect(page).to have_css('.seed-source-menu .dropdown-item', text: 'Retail outlet') }
  end

  context 'when the grower looks, with no photo for the hero' do
    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it 'has the source badge in the badge row, as a button that opens the choices' do
      expect(page).to have_css('.seed-badges .seed-source-menu button.seed-source-badge', text: "Saved by #{seed.owner}")
    end

    it('offers the other sources') { expect(page).to have_css('.seed-badges .dropdown-item', text: 'Retail outlet') }
  end
end
