require 'spec_helper'

feature "footer" do
  scenario "contact page has Twitter link" do
    visit root_path
    click_link 'Contact'
    page.should have_link '@growstufforg', :href => 'http://twitter.com/growstufforg'
  end
end
