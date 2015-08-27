require 'rails_helper'

feature 'Plantings RSS feed' do
  scenario 'The index feed exists' do
    visit plantings_path(format: 'rss')
    expect(page.status_code).to equal 200
  end

  scenario 'The index title is what we expect' do
    visit plantings_path(format: 'rss')
    expect(page).to have_content "Recent plantings from #{ @owner ? @owner : 'all members' } (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
