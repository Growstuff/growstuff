require 'rails_helper'

feature "signup" do

  scenario "sign up for new account from top menubar" do
    visit crops_path # something other than front page, which has multiple signup links
    click_link 'Sign up'
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    check 'member_tos_agreement'
    click_button 'Sign up'
    current_path.should eq root_path
  end

  scenario "sign up for new account with existing username" do
    visit crops_path # something other than front page, which has multiple signup links
    click_link 'Sign up'
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    check 'member_tos_agreement'
    click_button 'Sign up'
    page.has_content? 'A message with a confirmation link has been sent to your email address. Please open the link to activate your account.'
    current_path.should eq root_path
    first('.signup a').click # click the 'Sign up' button in the middle of the page
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    check 'member_tos_agreement'
    click_button 'Sign up'
    page.has_content? 'Login name has already been taken'
  end

  scenario "sign up for new account without accepting TOS" do
    visit root_path 
    first('.signup a').click # click the 'Sign up' button in the middle of the page
    fill_in 'Login name', with: 'person123'
    fill_in 'Email', with: 'gardener@example.com'
    fill_in 'Password', with: 'abc123'
    fill_in 'Password confirmation', with: 'abc123'
    # do not check 'member_tos_agreement'
    click_button 'Sign up'
    page.has_content? 'Tos agreement must be accepted'
    current_path.should eq members_path
  end

end
