require 'rails_helper'

feature "browse crops" do

  let(:tomato) { create :tomato }
  let(:maize)  { create :maize }
  let(:pending_crop)  { create :crop_request }
  let(:rejected_crop)  { create :rejected_crop }

  scenario "has a form for sorting by" do
    visit crops_path
    expect(page).to have_css "select#sort"
  end

  scenario "shows a list of crops" do
    crop1 = tomato
    visit crops_path
    expect(page).to have_content crop1.name
  end

  scenario "pending crops are not listed" do
    visit crops_path
    expect(page).not_to have_content pending_crop.name
  end

  scenario "rejected crops are not listed" do
    visit crops_path
    expect(page).not_to have_content rejected_crop.name
  end
end
