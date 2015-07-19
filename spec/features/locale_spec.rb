require 'rails_helper'

feature "Changing locales", :js => true do

  after do
    I18n.locale = :en
  end

  scenario "Locale can be set with a query param" do
    visit root_path
    expect(page).to have_content("a community of food gardeners.")
    visit root_path(:locale => 'ja')
    expect(page).to have_content("はガーデナーのコミュニティです。")
  end

end
