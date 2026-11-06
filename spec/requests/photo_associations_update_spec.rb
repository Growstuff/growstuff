# frozen_string_literal: true

require 'rails_helper'

# Saying what part of a seed a photo is of: the front or back of its packet.
describe PhotoAssociationsController, '#update' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:seed) { create(:seed, owner: member) }
  let(:photo) { create(:photo, owner: member) }
  let(:label) { 'front' }
  let(:path) { photo_association_path(photo_id: photo.id, type: 'seed', id: seed.id, label:) }

  before do
    seed.photo_associations.create!(photo:)
    sign_in member
  end

  context 'with front' do
    before { patch path }

    it('labels the photo') { expect(seed.photo_associations.pluck(:label)).to eq ['front'] }
    it('goes back to the seed') { expect(response).to redirect_to(seed) }
  end

  context 'with an empty label, for a photo that has one' do
    let(:label) { '' }

    before do
      seed.photo_associations.update_all(label: 'back') # rubocop:disable Rails/SkipsModelValidations
      patch path
    end

    it('takes the label off') { expect(seed.photo_associations.pluck(:label)).to eq [nil] }
  end

  context 'with a label that seeds do not have' do
    let(:label) { 'before' }

    before { patch path }

    it('leaves the photo alone') { expect(seed.photo_associations.pluck(:label)).to eq [nil] }
  end

  context 'when the seed is someone else\'s' do
    let(:seed) { create(:seed) }
    let(:photo) { create(:photo, owner: seed.owner) }

    before { patch path }

    it('is not found') { expect(response).to have_http_status(:not_found) }
    it('leaves the photo alone') { expect(seed.photo_associations.pluck(:label)).to eq [nil] }
  end

  context 'when the photo is not on the seed' do
    let(:other) { create(:photo, owner: member) }
    let(:path) { photo_association_path(photo_id: other.id, type: 'seed', id: seed.id, label:) }

    before { patch path }

    it('is not found') { expect(response).to have_http_status(:not_found) }
  end
end
