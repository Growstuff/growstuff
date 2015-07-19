require 'spec_helper'

feature 'Seeds RSS feed', :js => true do
  scenario 'The index feed exists' do
    visit seeds_path(:format => 'rss')
    expect(page.status_code).to equal 200
  end

  scenario 'The index title is what we expect' do
    visit seeds_path(:format => 'rss')
    expect(page).to have_content "Recent seeds from #{ @owner ? @owner : 'all members' } (#{ENV['GROWSTUFF_SITE_NAME']})"
  end
end
