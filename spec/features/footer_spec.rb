require 'rails_helper'

feature "footer", :js => true do

  scenario "has three columns" do
    visit root_path
    expect(page).to have_css 'footer #about-growstuff'
    expect(page).to have_css 'footer #policies'
    expect(page).to have_css 'footer #contact'
  end

# NB: not testing specific content in the footer since I'm going to put them
# in the CMS and they'll be variable.

  scenario "contact page has Twitter link" do
    visit root_path
    click_link 'Contact'
    page.should have_link '@growstufforg', :href => 'http://twitter.com/growstufforg'
  end
end
