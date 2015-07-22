require 'rails_helper'

feature "signin" do
  let(:member) { create :member }
  let(:recipient) { create :member }
  let(:notification) { create :notification }

  scenario "redirect to previous page after signin" do
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    expect(current_path).to eq crops_path
  end

  scenario "don't redirect to devise pages after signin" do
    visit new_member_registration_path # devise signup page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    expect(current_path).to eq root_path
  end

  scenario "redirect to signin page for if not authenticated to view notification" do
    visit notification_path(notification)
    expect(current_path).to eq new_member_session_path
  end

  scenario "after signin, redirect to what you were trying to do" do
    models = %w[plantings harvests posts photos gardens seeds]
    models.each do |model|
      visit "/#{model}/new"
      expect(current_path).to eq new_member_session_path
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      expect(current_path).to eq "/#{model}/new"
      click_link 'Sign out'
    end
  end

  scenario "after signin, redirect to new notifications page" do
    visit new_notification_path(recipient: recipient)
    expect(current_path).to eq new_member_session_path
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    expect(current_path).to eq new_notification_path
  end
end
