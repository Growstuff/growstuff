require 'spec_helper'

feature "Changing locales" do

  after do
    I18n.locale = :en
  end

  scenario "Locale can be set with a query param" do
    visit "/"
    expect(page).to have_content("a community of food gardeners.")
    visit "/?locale=ja"
    expect(page).to have_content("はガーデナーのコミュニティです。")    
  end

end