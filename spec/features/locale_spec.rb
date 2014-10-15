require 'spec_helper'

feature "Changing locales" do

  scenario "Locale can be set with a query param" do
    visit "/"
    expect(page).to have_content("a community of food gardeners.")
    visit "/?locale=ja"
    expect(page).to have_content("はガーデナーのコミュニティです。")    
  end

end