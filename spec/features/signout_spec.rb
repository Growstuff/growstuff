require 'rails_helper'

feature "signout" do
  let(:member) { create :member }

  scenario "redirect to previous page after signout" do
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    click_link 'Sign out'
    expect(current_path).to eq crops_path
  end

  shared_examples "sign-in redirects" do |path|
    scenario "after signout, redirect to signin page if page needs authentication" do
      visit path
      expect(current_path).to eq new_member_session_path
      expect(page).to have_http_status(200)
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      expect(page).to have_http_status(200)
      expect(current_path).to eq path
      click_link 'Sign out'
      expect(page).to have_http_status(200)
      expect(current_path).to eq new_member_session_path
    end
  end

  let(:path) {}

  describe 'after signout, redirect to signin page if page needs authentication' do
    include_examples "sign-in redirects", "/plantings/new"
    include_examples "sign-in redirects", "/harvests/new"
    include_examples "sign-in redirects", "/posts/new"
    include_examples "sign-in redirects", "/gardens/new"
    include_examples "sign-in redirects", "/seeds/new"
  end

  scenario 'photos' do
    garden = FactoryBot.create :garden, owner: member
    visit "/photos/new?id=#{garden.id}&type=garden"
    expect(current_path).to eq new_member_session_path
    expect(page).to have_http_status(200)
    # photos/new needs id&type params,
    # but these are stripped after signing in
  end
end
