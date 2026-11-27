# frozen_string_literal: true

require 'rails_helper'

# Adding a photo to a job, from the notepad's add-photo dialog: JSON, with the
# session cookie and CSRF token, and Flickr stubbed.
describe PhotosController, '#create' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:job) { create(:job, owner: member) }
  let(:item) { job }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def add_photo(label: nil)
    query = { type: item.class.model_name.singular, id: item.id, label: }.compact.to_query
    post "/photos.json?#{query}", params: { photo: { source_id: '1234', source: 'flickr' } }.to_json, headers: json_headers
  end

  before do
    sign_in member
    allow_any_instance_of(Photo).to receive(:set_flickr_metadata!) do |photo| # rubocop:disable RSpec/AnyInstance
      photo.update!(title: 'Net on', license_name: 'CC-BY', thumbnail_url: 'http://example.com/t.jpg',
                    fullsize_url: 'http://example.com/f.jpg', link_url: 'http://example.com/p')
    end
  end

  context 'with a label of before' do
    before { add_photo(label: 'before') }

    it 'puts the photo on the job' do
      expect(job.photos.pluck(:title)).to eq ['Net on']
    end

    it 'gives the label before' do
      expect(job.photo_associations.pluck(:label)).to eq ['before']
    end

    it 'answers that it was created' do
      expect(response).to have_http_status(:created)
    end
  end

  context 'with a label of after' do
    before { add_photo(label: 'after') }

    it 'gives the label after' do
      expect(job.photo_associations.pluck(:label)).to eq ['after']
    end
  end

  context 'without a label' do
    before { add_photo }

    it 'puts the photo on the job' do
      expect(job.photos.count).to eq 1
    end

    it 'says nothing of when it was taken' do
      expect(job.photo_associations.pluck(:label)).to eq [nil]
    end
  end

  context 'with an animal', flipper: :domesticated_animals do
    let(:item) { create(:domesticated_animal, owner: member) }

    it 'links the imported photo' do
      add_photo
      expect(item.photos.pluck(:title)).to eq ['Net on']
    end

    it 'unlinks the photo without deleting it' do
      add_photo
      photo = item.photos.first
      delete photo_association_path(photo_id: photo.id, type: 'domesticated_animal', id: item.id)
      expect(Photo.find_by(id: photo.id)).to eq photo
    end

    it 'removes the photo association' do
      add_photo
      delete photo_association_path(photo_id: item.photos.first.id, type: 'domesticated_animal', id: item.id)
      expect(item.photos.reload).to be_empty
    end

    context 'when the animal belongs to someone else' do
      let(:item) { create(:domesticated_animal) }

      it 'rejects the import' do
        add_photo
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when the feature is disabled' do
      before { Flipper.disable(:domesticated_animals) }

      it 'rejects the import' do
        add_photo
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context 'with a label that is not allowed' do
    before { add_photo(label: 'during') }

    it 'adds nothing' do
      expect(job.photos.count).to eq 0
    end

    it 'says what is wrong' do
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context 'when the photo is already on the job' do
    before do
      add_photo
      add_photo(label: 'after')
    end

    it 'does not add it again' do
      expect(job.photo_associations.count).to eq 1
    end

    it 'says when it was taken' do
      expect(job.photo_associations.pluck(:label)).to eq ['after']
    end
  end
end
