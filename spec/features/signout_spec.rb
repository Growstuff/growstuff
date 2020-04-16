# frozen_string_literal: true

require 'rails_helper'

describe "signout" do
  let(:member) { create :member }

  it "redirect to previous page after signout" do
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
    click_link member.login_name
    click_link 'Sign out'
    expect(page).to have_current_path crops_path, ignore_query: true
  end

  shared_examples "sign-in redirects" do |path|
    it "after signout, redirect to signin page if page needs authentication" do
      visit path
      expect(page).to have_current_path new_member_session_path, ignore_query: true
      # expect(page).to have_http_status(200)
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      # expect(page).to have_http_status(200)
      expect(page).to have_current_path path, ignore_query: true
      click_link member.login_name
      click_link 'Sign out'
      # expect(page).to have_http_status(200)
      expect(page).to have_current_path new_member_session_path, ignore_query: true
    end
  end

  describe 'after signout, redirect to signin page if page needs authentication' do
    include_examples "sign-in redirects", "/plantings/new"
    include_examples "sign-in redirects", "/harvests/new"
    include_examples "sign-in redirects", "/posts/new"
    include_examples "sign-in redirects", "/gardens/new"
    include_examples "sign-in redirects", "/seeds/new"
  end

  it 'photos' do
    garden = FactoryBot.create :garden, owner: member
    visit "/photos/new?id=#{garden.id}&type=garden"
    expect(page).to have_current_path new_member_session_path, ignore_query: true
    # expect(page).to have_http_status(200)
    # photos/new needs id&type params,
    # but these are stripped after signing in
  end
end
