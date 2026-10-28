# frozen_string_literal: true

require 'rails_helper'

# What a seed's own page says of the packet in its photos.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed) }
  let(:photo) { create(:photo, owner: seed.owner) }

  before { seed.photo_associations.create!(photo:, label: 'back') }

  context 'when its owner looks' do
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('lights the side it is') { expect(page).to have_css('.packet-label .btn.active', text: 'Back') }
    it('does not make the side it is a link') { expect(page).to have_no_link('Back') }
    it('offers to make it the front') { expect(page).to have_link('Front', href: /label=front/) }
    it('offers to say it is not of the packet') { expect(page).to have_link('None', href: /label=(&|$)/) }
    it('does not add a badge as well') { expect(page).to have_no_css('.packet-label .badge') }
  end

  context 'with the text read from the packet' do
    before do
      seed.update!(packet_text: 'Sow by: December 2026')
      sign_in seed.owner
      get seed_path(seed)
    end

    it('does not show it yet') { expect(response.body).not_to include('Sow by: December 2026') }
  end

  context 'when someone else looks' do
    let(:page) { Capybara.string(response.body) }

    before do
      sign_in create(:member)
      get seed_path(seed)
    end

    it('says it is the back of the packet') { expect(page).to have_css('.packet-label .badge', text: 'Back of packet') }
    it('offers no changes') { expect(page).to have_no_css('.packet-label .btn') }
  end
end
