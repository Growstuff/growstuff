require 'rails_helper'


feature "signin", js: true do
  let(:member) { create :member }
  let(:recipient) { create :member }
  let(:wrangler) { create :crop_wrangling_member }
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

  scenario "after crop wrangler signs in and crops await wrangling, show alert" do
    create :crop_request
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: wrangler.login_name
    fill_in 'Password', with: wrangler.password
    click_button 'Sign in'
    expect(page).to have_content("There are crops waiting to be wrangled.")
  end

  context "with facebook" do
     scenario "sign in" do
      # Ordinarily done by database_cleaner
      Member.where(login_name: 'tdawg').delete_all

      member = create :member, login_name: 'tdawg', email: 'example.oauth.facebook@example.com'

      # Start the test
      visit root_path 
      first('.signup a').click

      # Click the signup with facebook link

      first('a[href="/members/auth/facebook"]').click
      # Magic happens! 
      # See config/environments/test.rb for the fake user
      # that we pretended to auth as

      # Signed up and logged in
      expect(current_path).to eq root_path
      expect(page.text).to include("Welcome to #{ENV['GROWSTUFF_SITE_NAME']}, tdawg")
    end
  end
end
