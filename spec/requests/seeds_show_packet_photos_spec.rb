# frozen_string_literal: true

require 'rails_helper'

# What a seed's own page says of the packet in its photos.
describe SeedsController, '#show' do
  include Devise::Test::IntegrationHelpers

  let(:seed) { create(:seed) }
  let(:photo) { create(:photo, owner: seed.owner) }

  before { seed.photo_associations.create!(photo:, label: 'back') }

  context 'when its owner looks' do
    before do
      sign_in seed.owner
      get seed_path(seed)
    end

    it('says it is the back of the packet') { expect(response.body).to include('Back of packet') }
    it('offers to make it the front') { expect(response.body).to include('Mark as front of packet') }
    it('offers to say it is not a packet') { expect(response.body).to include('Not a packet') }
    it('does not offer what it already is') { expect(response.body).not_to include('Mark as back of packet') }
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
    before do
      sign_in create(:member)
      get seed_path(seed)
    end

    it('says it is the back of the packet') { expect(response.body).to include('Back of packet') }
    it('offers no changes') { expect(response.body).not_to include('Mark as front of packet') }
  end
end
