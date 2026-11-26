# frozen_string_literal: true

require 'rails_helper'

describe CommunityGardenImportService do
  subject(:service) { described_class.new(bbox: bbox, out: StringIO.new) }

  let(:bbox) { '-37.9,144.9,-37.7,145.1' }

  describe '#build_query' do
    context 'when bbox is provided' do
      it 'substitutes bbox into query' do
        query = service.build_query
        expect(query).to include('nwr["leisure"="garden"]["garden:type"="community"](-37.9,144.9,-37.7,145.1);')
        expect(query).to include('out geom;')
      end
    end

    context 'when bbox is blank' do
      let(:bbox) { nil }

      it 'removes bbox filter parentheses from query' do
        query = service.build_query
        expect(query).to include('nwr["leisure"="garden"]["garden:type"="community"];')
        expect(query).not_to include('{{bbox}}')
      end
    end
  end

  describe '#call' do
    let(:overpass_response) do
      {
        'elements' => [
          {
            'type' => 'node',
            'id' => 1001,
            'lat' => -37.8136,
            'lon' => 144.9631,
            'tags' => {
              'name' => 'Collingwood Community Garden',
              'website' => 'https://collingwoodgarden.org',
              'contact:email' => 'contact@collingwoodgarden.org',
              'wikidata' => 'Q99999',
              'description' => 'A community plot in Collingwood.'
            }
          },
          {
            'type' => 'way',
            'id' => 2002,
            'geometry' => [
              { 'lat' => -37.8000, 'lon' => 144.9000 },
              { 'lat' => -37.8020, 'lon' => 144.9020 }
            ],
            'tags' => {
              'official_name' => 'Fitzroy Urban Garden'
            }
          }
        ]
      }.to_json
    end

    before do
      response_mock = instance_double(Net::HTTPSuccess, is_a?: true, body: overpass_response)
      allow(Net::HTTP).to receive(:post_form).and_return(response_mock)
    end

    it 'imports community garden records' do
      expect { service.call }.to change(CommunityGarden, :count).by(2)

      garden1 = CommunityGarden.find_by(osm_id: 'node/1001')
      expect(garden1.title).to eq('Collingwood Community Garden')
      expect(garden1.website).to eq('https://collingwoodgarden.org')
      expect(garden1.email).to eq('contact@collingwoodgarden.org')
      expect(garden1.wikidata_id).to eq('Q99999')
      expect(garden1.description).to eq('A community plot in Collingwood.')
      expect(garden1.coordinates).to eq('-37.8136, 144.9631')

      garden2 = CommunityGarden.find_by(osm_id: 'way/2002')
      expect(garden2.title).to eq('Fitzroy Urban Garden')
      expect(garden2.coordinates).to eq('-37.801, 144.901')
    end

    it 'updates existing garden on re-import' do
      create(:community_garden, osm_id: 'node/1001', title: 'Old Name')

      expect { service.call }.to change(CommunityGarden, :count).by(1)
      expect(CommunityGarden.find_by(osm_id: 'node/1001').title).to eq('Collingwood Community Garden')
    end
  end
end
