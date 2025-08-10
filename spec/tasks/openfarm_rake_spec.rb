# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'openfarm:delete_pictures' do
  before(:all) do
    Rails.application.load_tasks
  end

  # We need to do this because Rake tasks normally output to STDOUT, but we
  # don't want to clutter up the test output.
  before(:each) do
    $stdout = StringIO.new
  end

  after(:each) do
    $stdout = STDOUT
  end

  it 'deletes pictures with source OpenFarm' do
    create(:photo, source: 'OpenFarm')
    create(:photo, source: 'flickr')

    expect(Photo.where(source: 'OpenFarm').count).to eq(1)
    expect(Photo.where(source: 'flickr').count).to eq(1)

    Rake::Task['openfarm:delete_pictures'].invoke

    expect(Photo.where(source: 'OpenFarm').count).to eq(0)
    expect(Photo.where(source: 'flickr').count).to eq(1)
  end
end
