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
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      expect(current_path).to eq path
      click_link 'Sign out'
      expect(current_path).to eq new_member_session_path
    end
  end

  let(:path) {}
  describe 'most models' do
    let(:garden) { FactoryBot.create :garden, owner: member }
    include_examples "sign-in redirects", "/plantings/new"
    include_examples "sign-in redirects", "/harvests/new"
    include_examples "sign-in redirects", "/posts/new"
    include_examples "sign-in redirects", "/gardens/new"
    include_examples "sign-in redirects", "/seeds/new"
    include_examples "sign-in redirects", "/photos/new?type=garden&id=1"
  end
end
