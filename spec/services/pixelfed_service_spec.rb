# frozen_string_literal: true

require 'rails_helper'

describe PixelfedService do
  describe '.extract_metadata' do
    let(:activity_pub_object) do
      {
        '@context' => 'https://www.w3.org/ns/activitystreams',
        'id' => 'https://pixelfed.example.com/p/alice/123456789',
        'type' => 'Note',
        'summary' => nil,
        'name' => 'Fresh heirloom tomatoes',
        'content' => '<p>Look at my fresh harvested tomatoes!</p>',
        'published' => '2025-02-01T12:00:00Z',
        'url' => 'https://pixelfed.example.com/p/alice/123456789',
        'attributedTo' => 'https://pixelfed.example.com/users/alice',
        'attachment' => [
          {
            'type' => 'Document',
            'mediaType' => 'image/jpeg',
            'url' => 'https://pixelfed.example.com/storage/m/_v2/123/full.jpg',
            'name' => 'Tomatoes in a basket',
            'icon' => {
              'type' => 'Image',
              'url' => 'https://pixelfed.example.com/storage/m/_v2/123/thumb.jpg'
            }
          }
        ],
        'license' => 'https://creativecommons.org/licenses/by/4.0/'
      }
    end

    context 'with a valid ActivityPub hash input' do
      it 'extracts the photo metadata correctly' do
        metadata = described_class.extract_metadata(activity_pub_object)

        expect(metadata).to eq(
          source: 'pixelfed',
          source_id: 'https://pixelfed.example.com/p/alice/123456789',
          title: 'Fresh heirloom tomatoes',
          fullsize_url: 'https://pixelfed.example.com/storage/m/_v2/123/full.jpg',
          thumbnail_url: 'https://pixelfed.example.com/storage/m/_v2/123/thumb.jpg',
          link_url: 'https://pixelfed.example.com/p/alice/123456789',
          license_name: 'CC-BY 4.0',
          license_url: 'https://creativecommons.org/licenses/by/4.0/',
          date_taken: Time.zone.parse('2025-02-01T12:00:00Z')
        )
      end
    end

    context 'with a Create activity object containing an inner object' do
      let(:create_activity) do
        {
          '@context' => 'https://www.w3.org/ns/activitystreams',
          'id' => 'https://pixelfed.example.com/activity/123',
          'type' => 'Create',
          'object' => activity_pub_object
        }
      end

      it 'extracts metadata from the nested object' do
        metadata = described_class.extract_metadata(create_activity)
        expect(metadata[:source_id]).to eq('https://pixelfed.example.com/p/alice/123456789')
        expect(metadata[:title]).to eq('Fresh heirloom tomatoes')
      end
    end

    context 'with a JSON string input' do
      it 'parses JSON and extracts metadata' do
        json_string = activity_pub_object.to_json
        metadata = described_class.extract_metadata(json_string)

        expect(metadata[:title]).to eq('Fresh heirloom tomatoes')
        expect(metadata[:fullsize_url]).to eq('https://pixelfed.example.com/storage/m/_v2/123/full.jpg')
      end
    end

    context 'with a URL input' do
      let(:url) { 'https://pixelfed.example.com/p/alice/123456789' }
      let(:faraday_response) do
        instance_double(Faraday::Response, success?: true, status: 200, body: activity_pub_object.to_json)
      end

      before do
        allow(Faraday).to receive(:get)
          .with(url, nil, PixelfedService::ACTIVITY_PUB_HEADERS)
          .and_return(faraday_response)
      end

      it 'fetches the URL and extracts metadata' do
        metadata = described_class.extract_metadata(url)
        expect(metadata[:source_id]).to eq(url)
        expect(metadata[:title]).to eq('Fresh heirloom tomatoes')
      end
    end

    context 'when payload has no image attachments' do
      let(:invalid_object) do
        {
          'id' => 'https://pixelfed.example.com/p/alice/999',
          'type' => 'Note',
          'content' => 'Just text no image'
        }
      end

      it 'raises a PixelfedService::Error' do
        expect { described_class.extract_metadata(invalid_object) }
          .to raise_error(PixelfedService::Error, 'No image found in ActivityPub object')
      end
    end

    context 'when payload is missing an id' do
      let(:invalid_object) do
        {
          'type' => 'Note',
          'content' => 'No ID'
        }
      end

      it 'raises a PixelfedService::Error' do
        expect { described_class.extract_metadata(invalid_object) }
          .to raise_error(PixelfedService::Error, 'ActivityPub object missing id')
      end
    end
  end
end
