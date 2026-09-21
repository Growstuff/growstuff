# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'wikidata:import_alternate_names' do
  before :all do
    Rails.application.load_tasks
  end

  before do
    Rake::Task['wikidata:import_alternate_names'].reenable
  end

  it 'outputs error message if no admin member exists' do
    expect { Rake::Task['wikidata:import_alternate_names'].invoke }.to output(/Could not find an admin member/).to_stdout
  end

  it 'processes crops with preloaded scientific_names' do
    admin = create(:member, admin: true)
    crop = create(:crop, name: 'Tomato')
    create(:scientific_name, crop: crop, name: 'Solanum lycopersicum', wikidata_id: 'Q1387')

    wikidata_response = {
      'entities' => {
        'Q1387' => {
          'aliases' => {
            'en' => [{ 'value' => 'Love Apple' }]
          }
        }
      }
    }.to_json

    allow(Net::HTTP).to receive(:get).and_return(wikidata_response)

    expect { Rake::Task['wikidata:import_alternate_names'].invoke }.to output(/Added alternate name: Love Apple/).to_stdout

    expect(AlternateName.exists?(name: 'Love Apple', language: 'en', crop: crop, creator: admin)).to be true
  end
end
