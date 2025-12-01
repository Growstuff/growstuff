require 'rails_helper'
require 'rake'

describe 'sitemap:cached_refresh' do
  let(:sitemap_file) { Rails.root.join('tmp', 'sitemap_generated_at.txt') }

  before :all do
    Rails.application.load_tasks
  end

  before :each do
    Rake::Task['sitemap:refresh'].clear
    File.delete(sitemap_file) if File.exist?(sitemap_file)
  end

  after :each do
    File.delete(sitemap_file) if File.exist?(sitemap_file)
  end

  it 'calls sitemap:refresh if the cache file does not exist' do
    expect(Rake::Task['sitemap:refresh']).to receive(:invoke)
    Rake::Task['sitemap:cached_refresh'].invoke
  end

  it 'calls sitemap:refresh if the cache file is older than 72 hours' do
    File.write(sitemap_file, 73.hours.ago.to_s)
    expect(Rake::Task['sitemap:refresh']).to receive(:invoke)
    Rake::Task['sitemap:cached_refresh'].reenable
    Rake::Task['sitemap:cached_refresh'].invoke
  end

  it 'does not call sitemap:refresh if the cache file is newer than 72 hours' do
    File.write(sitemap_file, 71.hours.ago.to_s)
    expect(Rake::Task['sitemap:refresh']).not_to receive(:invoke)
    Rake::Task['sitemap:cached_refresh'].reenable
    Rake::Task['sitemap:cached_refresh'].invoke
  end
end
