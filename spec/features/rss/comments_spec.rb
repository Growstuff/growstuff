require 'spec_helper'

feature 'Comments RSS feed' do
  scenario 'This RSS feed exists' do
    visit comments_path(:format => 'rss')
    expect(page.status_code).to equal 200
  end

  scenario 'The feed title is what we expect' do
    visit comments_path(:format => 'rss')
    expect(page).to have_content "#{ENV['GROWSTUFF_SITE_NAME']} - Recent comments on all posts"
  end
end