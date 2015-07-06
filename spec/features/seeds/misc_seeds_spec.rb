require 'rails_helper'

feature "seeds" do
  context "signed in user" do
    
    let(:member) { @member = FactoryGirl.create(:member) }
    let(:crop) { FactoryGirl.create(:crop) }

    background do
      login_as member
    end

    scenario "button on index to edit seed" do
      seed = FactoryGirl.create(:seed, :owner => @member)
      visit seeds_path
      click_link "Edit"
      current_path.should eq edit_seed_path(seed)
      page.should have_content 'Editing seeds'
    end

    scenario "button on front page to add seeds" do
      visit root_path
      click_link "Add seeds"
      current_path.should eq new_seed_path
      page.should have_content 'Add seeds'
    end

    # actually adding seeds is in spec/features/seeds_new_spec.rb

    scenario "edit seeds" do
      seed = FactoryGirl.create(:seed, :owner => @member)
      visit seed_path(seed)
      click_link 'Edit'
      current_path.should eq edit_seed_path(seed)
      fill_in 'Quantity:', :with => seed.quantity * 2
      click_button 'Save'
      current_path.should eq seed_path(seed)
    end

    scenario "delete seeds" do
      seed = FactoryGirl.create(:seed, :owner => @member)
      visit seed_path(seed)
      click_link 'Delete'
      current_path.should eq seeds_path
    end

    scenario "view seeds with max and min days until maturity" do
      seed = FactoryGirl.create(:seed, :days_until_maturity_min => 5, :days_until_maturity_max => 7)
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: 5–7"
    end

    scenario "view seeds with only max days until maturity" do
      seed = FactoryGirl.create(:seed, :days_until_maturity_max => 7)
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: 7"
    end

    scenario "view seeds with only min days until maturity" do
      seed = FactoryGirl.create(:seed, :days_until_maturity_min => 5)
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: 5"
    end

    scenario "view seeds with neither max nor min days until maturity" do
      seed = FactoryGirl.create(:seed)
      visit seed_path(seed)
      expect(page).to have_content "Days until maturity: unknown"
    end

  end
end
