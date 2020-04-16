# frozen_string_literal: true

require 'rails_helper'

describe "signup", js: true do
  it "sign up for new account from top menubar" do
    visit crops_path # something other than front page, which has multiple signup links
    click_link 'Sign up'
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    check 'member_tos_agreement'
    click_button 'Sign up'
    expect(page).to have_current_path root_path, ignore_query: true
  end

  it "sign up for new account with existing username" do
    visit crops_path # something other than front page, which has multiple signup links
    click_link 'Sign up'
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    check 'member_tos_agreement'
    click_button 'Sign up'
    expect(page).to have_current_path root_path, ignore_query: true
    first('.signup a').click # click the 'Sign up' button in the middle of the page
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    check 'member_tos_agreement'
    click_button 'Sign up'
  end

  it "sign up for new account without accepting TOS" do
    visit root_path
    first('.signup a').click # click the 'Sign up' button in the middle of the page
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    # do not check 'member_tos_agreement'
    click_button 'Sign up'
    expect(page).to have_current_path members_path, ignore_query: true
  end

  context "with facebook" do
    it "sign up" do
      # Ordinarily done by database_cleaner
      Member.where(login_name: 'tdawg').delete_all
      Member.where(email: 'tdawg@hotmail.com').delete_all
      Member.where(email: 'example.oauth.facebook@example.com').delete_all
      Authentication.where(provider: 'facebook', uid: '123545').delete_all

      # Start the test
      visit root_path
      first('.signup a').click

      # Click the signup with facebook link

      first('a[href="/members/auth/facebook"]').click
      # Magic happens!
      # See config/environments/test.rb for the fake user
      # that we pretended to auth as

      # Confirm page
      expect(page).to have_current_path '/members/johnnyt/finish_signup'

      fill_in 'Login name', with: 'tdawg'
      fill_in 'Email', with: 'tdawg@hotmail.com'
      check 'member_tos_agreement'
      click_button 'Continue'

      # Signed up and logged in
      expect(page).to have_current_path root_path, ignore_query: true
      expect(page.text).to include("Welcome to #{ENV['GROWSTUFF_SITE_NAME']}, tdawg")
    end
  end
end
