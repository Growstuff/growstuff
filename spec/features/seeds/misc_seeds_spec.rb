require 'rails_helper'

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

    scenario "button on index to edit seed" do
      seed = FactoryGirl.create(:seed, :owner => @member)
      visit seeds_path
      click_link "Edit"
      current_path.should eq edit_seed_path(seed)
      page.should have_content 'Editing seeds'
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
  end
end
