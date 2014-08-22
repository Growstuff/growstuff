require 'spec_helper'

feature "seeds" do
  context "signed in user" do
    before(:each) do
      @crop = FactoryGirl.create(:crop)
      @member = FactoryGirl.create(:member)
      visit root_path
      click_link 'Sign in'
      fill_in 'Login', :with => @member.login_name
      fill_in 'Password', :with => @member.password
      click_button 'Sign in'
    end

    scenario "button on front page to add seeds" do
      visit root_path
      click_link "Add seeds"
      current_path.should eq new_seed_path
      page.should have_content 'Add seeds'
    end

    scenario "add seeds" do
      visit new_seed_path
      page.should have_content 'Add seeds'
      select @crop.name, :from => 'seed_crop_id'
      fill_in 'seed_quantity', :with => 3
      fill_in 'seed_plant_before', :with => '2020-01-01'
      fill_in 'seed_description', :with => "these are some seeds I harvested"
      select "nowhere", :from => 'seed_tradable_to'
      click_button 'Save'
      current_path.should eq seed_path(Seed.last)
    end

    scenario "edit seeds" do
      seed = FactoryGirl.create(:seed, :owner => @member)
      visit seed_path(seed)
      click_link 'Edit'
      current_path.should eq edit_seed_path(seed)
      fill_in 'seed_quantity', :with => seed.quantity * 2
      click_button 'Save'
      current_path.should eq seed_path(seed)
    end

    scenario "delete seeds" do
      seed = FactoryGirl.create(:seed, :owner => @member)
      visit seed_path(seed)
      click_link 'Delete'
      current_path.should eq seeds_path
    end
  end
end
