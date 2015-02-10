require 'rails_helper'

feature "browse crops" do

  let(:tomato) { FactoryGirl.create(:tomato) }
  let(:maize)  { FactoryGirl.create(:maize) }

  scenario "has a form for sorting by" do
    visit crops_path
    expect(page).to have_css "select#sort"
  end

  scenario "shows a list of crops" do
    crop1 = tomato
    visit crops_path
    expect(page).to have_content crop1.name
  end

end
