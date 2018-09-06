require 'rails_helper'

feature 'Comments RSS feed' do
  scenario 'The index feed exists' do
    visit comments_path(format: 'rss')
    expect(page.status_code).to equal 200
  end

  scenario 'The index title is what we expect' do
    visit comments_path(format: 'rss')
    expect(page).to have_content "Recent comments on all posts (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
