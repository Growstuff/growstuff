# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'community_gardens:import' do
  before :all do
    Rails.application.load_tasks
  end

  before do
    Rake::Task['community_gardens:import'].reenable
  end

  it 'invokes CommunityGardenImportService with specified bbox' do
    service_double = instance_double(CommunityGardenImportService, call: 1)
    allow(CommunityGardenImportService).to receive(:new).with(bbox: '-37.9,144.9,-37.7,145.1').and_return(service_double)

    Rake::Task['community_gardens:import'].invoke('-37.9,144.9,-37.7,145.1')

    expect(service_double).to have_received(:call)
  end
end
