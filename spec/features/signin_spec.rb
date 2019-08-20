require 'rails_helper'

describe "signin", js: true do
  let(:member)       { FactoryBot.create :member                             }
  let(:recipient)    { FactoryBot.create :member                             }
  let(:wrangler)     { FactoryBot.create :crop_wrangling_member              }

  def login
    fill_in 'Login', with: member.login_name
    fill_in 'Password', with: member.password
    click_button 'Sign in'
  end

  it "via email address" do
    visit crops_path # some random page
    click_link 'Sign in'
    login
    expect(page).to have_content("Sign out")
  end

  it "redirect to previous page after signin" do
    visit crops_path # some random page
    click_link 'Sign in'
    login
    expect(current_path).to eq crops_path
  end

  it "don't redirect to devise pages after signin" do
    visit new_member_registration_path # devise signup page
    click_link 'Sign in'
    login
    expect(current_path).to eq root_path
  end

  describe "redirect to signin page for if not authenticated to view conversations" do
    before do
      conversation = member.send_message(recipient, 'hey there', 'kiaora')
      visit conversation_path(conversation)
    end
    it { expect(current_path).to eq new_member_session_path }
  end

  shared_examples "redirects to what you were trying to do" do
    it do
      visit "/#{model_name}/new"
      expect(current_path).to eq new_member_session_path
      login
      expect(current_path).to eq "/#{model_name}/new"
    end
  end

  describe "redirects to what you were trying to do" do
    %w(plantings harvests posts gardens seeds).each do |m|
      it_behaves_like "redirects to what you were trying to do" do
        let(:model_name) { m }
      end
    end
  end

  it "after signin, redirect to new message page" do
    visit new_message_path(recipient_id: recipient.id)
    expect(current_path).to eq new_member_session_path
    login
    expect(current_path).to eq new_message_path
  end

  it "after crop wrangler signs in and crops await wrangling, show alert" do
    create :crop_request
    visit crops_path # some random page
    click_link 'Sign in'
    fill_in 'Login', with: wrangler.login_name
    fill_in 'Password', with: wrangler.password
    click_button 'Sign in'
    expect(page).to have_content("There are crops waiting to be wrangled.")
  end

  context "with facebook" do
    it "sign in" do
      # Ordinarily done by database_cleaner
      Member.where(login_name: 'tdawg').delete_all

      create :member, login_name: 'tdawg', email: 'example.oauth.facebook@example.com'

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
