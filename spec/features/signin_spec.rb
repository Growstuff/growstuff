require 'spec_helper'

feature "signin" do
  let(:member){FactoryGirl.create(:member)}

  scenario "redirect to previous page after signin" do
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    current_path.should eq crops_path
  end

  scenario "don't redirect to devise pages after signin" do
    visit new_member_registration_path # devise signup page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    current_path.should eq root_path
  end

end
