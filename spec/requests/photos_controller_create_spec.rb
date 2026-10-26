# frozen_string_literal: true

require 'rails_helper'

# Adding a photo to a job, from the notepad's add-photo dialog: JSON, with the
# session cookie and CSRF token, and Flickr stubbed.
describe PhotosController, '#create' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:job) { create(:job, owner: member) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def add_photo(moment: nil)
    query = { type: 'job', id: job.id, moment: }.compact.to_query
    post "/photos.json?#{query}", params: { photo: { source_id: '1234', source: 'flickr' } }.to_json, headers: json_headers
  end

  before do
    sign_in member
    allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) do |photo| # rubocop:disable RSpec/AnyInstance
      photo.update!(title: 'Net on', license_name: 'CC-BY', thumbnail_url: 'http://example.com/t.jpg',
                    fullsize_url: 'http://example.com/f.jpg', link_url: 'http://example.com/p')
    end
  end

  context 'with a moment of before' do
    before { add_photo(moment: 'before') }

    it 'puts the photo on the job' do
      expect(job.photos.pluck(:title)).to eq ['Net on']
    end

    it 'says it was taken before' do
      expect(job.photo_associations.pluck(:moment)).to eq ['before']
    end

    it 'answers that it was created' do
      expect(response).to have_http_status(:created)
    end
  end

  context 'with a moment of after' do
    before { add_photo(moment: 'after') }

    it 'says it was taken after' do
      expect(job.photo_associations.pluck(:moment)).to eq ['after']
    end
  end

  context 'without a moment' do
    before { add_photo }

    it 'puts the photo on the job' do
      expect(job.photos.count).to eq 1
    end

    it 'says nothing of when it was taken' do
      expect(job.photo_associations.pluck(:moment)).to eq [nil]
    end
  end

  context 'with a moment that is not allowed' do
    before { add_photo(moment: 'during') }

    it 'adds nothing' do
      expect(job.photos.count).to eq 0
    end

    it 'says what is wrong' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when the photo is already on the job' do
    before do
      add_photo
      add_photo(moment: 'after')
    end

    it 'does not add it again' do
      expect(job.photo_associations.count).to eq 1
    end

    it 'says when it was taken' do
      expect(job.photo_associations.pluck(:moment)).to eq ['after']
    end
  end

  context 'with a pixelfed photo' do
    let(:pixelfed_url) { 'https://pixelfed.social/p/gardener/987654321' }

    before do
      allow(PixelfedService).to receive(:extract_metadata).with(pixelfed_url).and_return(
        source: 'pixelfed',
        source_id: pixelfed_url,
        title: 'Pixelfed Garden Note',
        fullsize_url: 'http://example.com/pixelfed_full.jpg',
        thumbnail_url: 'http://example.com/pixelfed_thumb.jpg',
        link_url: pixelfed_url,
        license_name: 'CC-BY'
      )

      query = { type: 'job', id: job.id }.to_query
      post "/photos.json?#{query}", params: { photo: { source: 'pixelfed', pixelfed_url: pixelfed_url } }.to_json, headers: json_headers
    end

    it 'attaches the pixelfed photo to the job' do
      expect(job.photos.pluck(:title)).to eq ['Pixelfed Garden Note']
      expect(job.photos.first.source).to eq 'pixelfed'
    end
  end
end
