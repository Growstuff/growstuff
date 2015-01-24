require 'rails_helper'

feature "Changing locales" do

  after do
    I18n.locale = :en
  end

  scenario "Locale can be set with a query param" do
    visit root_path
    expect(page).to have_content("A community of food growers")
    visit root_path(:locale => 'ja')
    expect(page).to have_content("ガーデナーのコミュニティです")
  end

end
