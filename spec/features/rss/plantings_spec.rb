# frozen_string_literal: true

require 'rails_helper'

describe 'Plantings RSS feed' do
  it 'The index feed exists' do
    visit plantings_path(format: 'rss')
    # expect(page.status_code).to equal 200
  end

  it 'The index title is what we expect' do
    Planting.reindex
    visit plantings_path(format: 'rss')
    expect(page).to have_content "Recent plantings from "\
      "#{@owner || 'all members'} (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
