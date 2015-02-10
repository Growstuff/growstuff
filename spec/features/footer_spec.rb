require 'rails_helper'

feature "footer" do

  scenario "footer is on home page" do
    visit root_path
    expect(page).to have_css 'footer'
  end

# NB: not testing specific content in the footer since I'm going to put them
# in the CMS and they'll be variable.
end
