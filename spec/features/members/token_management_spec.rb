# frozen_string_literal: true

require 'rails_helper'

describe "member token management", :js do
  include_context 'signed in member'

  before do
    visit edit_member_registration_path
    click_on "Apps"
  end

  it "can generate an API token" do
    expect(page).to have_no_content("Your API token is")
    click_on "Generate API Token"
    expect(page).to have_content("Your API token is")
    expect(member.api_token).to be_present
  end

  context "with an existing token" do
    before do
      member.regenerate_api_token
      visit edit_member_registration_path
      click_on "Apps"
    end

    it "can regenerate an API token" do
      old_token = member.api_token.token
      expect(page).to have_content("Your API token is")
      click_on "Regenerate"
      expect(page).to have_content("Your API token is")
      expect(member.reload.api_token.token).not_to eq(old_token)
    end
  end
end
