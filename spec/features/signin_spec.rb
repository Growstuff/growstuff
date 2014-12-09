require 'spec_helper'

feature "signin" do
  let(:member){FactoryGirl.create(:member)}
  let(:notification){FactoryGirl.create(:notification)}

  MODELS = [:plantings, :harvests, :posts, :photos, :gardens, :seeds]

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

  scenario "redirect to signin page for if not authenticated to view notification" do
    visit notification_path(notification)
    current_path.should eq new_member_session_path
  end

  scenario "after signin, redirect to what you were trying to do" do
    MODELS.each do |model|
      visit "/#{model.to_s}/new"
      current_path.should eq new_member_session_path
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      current_path.should eq "/#{model.to_s}/new"
      click_link 'Sign out'
    end
  end

end
