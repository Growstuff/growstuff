require 'rails_helper'

feature 'Crops RSS feed' do
  scenario 'The index feed exists' do
    visit crops_path(format: 'rss')
    expect(page.status_code).to equal 200
  end

  scenario 'The index title is what we expect' do
    visit crops_path(format: 'rss')
    expect(page).to have_content "Recently added crops (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
