require 'spec_helper'

shared_examples "crop suggest" do |resource|
  let!(:popcorn) { FactoryGirl.create(:popcorn) }
  let!(:pear)    { FactoryGirl.create(:pear) }

  scenario "Typing in the crop name displays suggestions" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "p"
    end

    expect(page).to have_content("pear")
    expect(page).to have_content("popcorn")

    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "pe"
    end

    expect(page).to have_content("pear")
    expect(page).to_not have_content("popcorn")
    expect(page).to have_selector("input##{resource}_crop_id[value='#{pear.id}']", :visible => false)
  end

end