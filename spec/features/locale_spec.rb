require 'spec_helper'

feature "Changing locales" do

  scenario "Locale can be set with a query param" do
    visit "/"
    expect(page).to have_content("Growstuff (dev) is a community of food gardeners.")
    visit "/?locale=ja"
    expect(page).to have_content("Growstuff (dev)はガーデナーのコミュニティです。")    
  end

end