# frozen_string_literal: true

require 'rails_helper'

# Adding a photo of a seed's packet, front or back, with Flickr stubbed.
describe PhotosController, '#create' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:seed) { create(:seed, owner: member) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:label) { nil }

  before do
    sign_in member
    allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) do |photo| # rubocop:disable RSpec/AnyInstance
      photo.update!(title: 'Packet', license_name: 'CC-BY', thumbnail_url: 'http://example.com/t.jpg',
                    fullsize_url: 'http://example.com/f.jpg', link_url: 'http://example.com/p')
    end
    query = { type: 'seed', id: seed.id, label: }.compact.to_query
    post "/photos.json?#{query}", params: { photo: { source_id: '1234', source: 'flickr' } }.to_json, headers: json_headers
  end

  context 'with a label of back' do
    let(:label) { 'back' }

    it('says it is the back') { expect(seed.photo_associations.pluck(:label)).to eq ['back'] }
    it('answers that it was created') { expect(response).to have_http_status(:created) }
  end

  context 'without a label' do
    it('says nothing of the packet') { expect(seed.photo_associations.pluck(:label)).to eq [nil] }
  end

  context 'with a label that is not allowed' do
    let(:label) { 'top' }

    it('adds nothing') { expect(seed.photos.count).to eq 0 }
    it('says what is wrong') { expect(response).to have_http_status(:unprocessable_entity) }
  end
end
