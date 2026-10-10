# frozen_string_literal: true

require 'rails_helper'

# GET /photos/new.json and POST /photos.json are for our own React garden cards
# only: session cookie and CSRF token, same origin. Flickr is stubbed.
describe 'Adding a photo as JSON' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let!(:planting) { create(:planting, garden: garden, owner: member) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:flickr_photo) { Struct.new(:id, :title, :farm, :server, :secret).new('1234', 'Cabbage', 1, '65535', 'abc123') }

  def choose_photos(**params)
    get '/photos/new.json', params: { type: 'planting', id: planting.id, **params }, headers: { 'ACCEPT' => 'application/json' }
  end

  def add_photo(type: 'planting', id: planting.id)
    post "/photos.json?type=#{type}&id=#{id}", params: { photo: { source_id: '1234', source: 'flickr' } }.to_json, headers: json_headers
  end

  context 'when signed in' do
    before { sign_in member }

    describe 'choosing a photo' do
      it 'says to connect Flickr when the member has not' do
        choose_photos

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq('state' => 'connect', 'connect_url' => '/members/auth/flickr')
      end

      it 'says to reconnect when the Flickr token has gone stale' do
        create(:flickr_authentication, member: member)
        allow_any_instance_of(Member).to receive(:flickr_auth_valid?).and_return(false) # rubocop:disable RSpec/AnyInstance

        choose_photos

        expect(response.parsed_body['state']).to eq 'reconnect'
        expect(member.authentications.where(provider: 'flickr')).to be_empty
      end

      context 'with Flickr connected' do
        before do
          create(:flickr_authentication, member: member, name: 'Gardener')
          allow_any_instance_of(Member).to receive_messages(flickr_auth_valid?: true, flickr_sets: { 'Spring' => '77' }, flickr_photos: [[flickr_photo], 61]) # rubocop:disable RSpec/AnyInstance
        end

        it 'gives a page of photos, with the albums to choose from' do
          choose_photos(page: 2)

          body = response.parsed_body
          expect(body).to include('state' => 'ready', 'name' => 'Gardener', 'page' => 2, 'total' => 61, 'total_pages' => 3,
                                  'sets' => [{ 'id' => '77', 'title' => 'Spring' }])
          expect(body['photos'].first).to include('id' => '1234', 'title' => 'Cabbage')
          expect(body['photos'].first['thumb_url']).to start_with('https://')
        end
      end
    end

    describe 'adding it' do
      before do
        allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) do |photo| # rubocop:disable RSpec/AnyInstance
          photo.update!(title: 'Cabbage', license_name: 'CC-BY', thumbnail_url: 'http://example.com/t.jpg',
                        fullsize_url: 'http://example.com/f.jpg', link_url: 'http://example.com/p')
        end
      end

      it "puts the photo on the planting and returns the garden's refreshed card" do
        expect { add_photo }.to change { planting.photos.count }.by(1)

        expect(response).to have_http_status(:created)
        photo = planting.photos.last
        expect(response.parsed_body['photo']).to eq('id' => photo.id, 'url' => "/photos/#{photo.id}")
        expect(response.parsed_body.dig('garden', 'id')).to eq garden.id
        expect(photo).to have_attributes(owner: member, source: 'flickr', source_id: '1234', title: 'Cabbage')
      end

      it 'puts it on a garden too' do
        expect { add_photo(type: 'garden', id: garden.id) }.to change { garden.photos.count }.by(1)

        expect(response.parsed_body.dig('garden', 'id')).to eq garden.id
      end
    end

    it 'returns validation errors as 422 and adds nothing when Flickr gives back nothing usable' do
      allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) # rubocop:disable RSpec/AnyInstance

      expect { add_photo }.not_to(change(Photo, :count))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to have_key('title')
    end
  end

  it 'asks a visitor who is not signed in to sign in' do
    choose_photos
    expect(response).to have_http_status(:unauthorized)
  end
end
