require 'rails_helper'

feature "Changing locales", js: true do

  after { I18n.locale = :en }

  scenario "Locale can be set with a query param" do
    visit root_path
    expect(page).to have_content("a community of food gardeners.")
    visit root_path(locale: 'ja')
    expect(page).to have_content("はガーデナーのコミュニティです。")
  end
end
