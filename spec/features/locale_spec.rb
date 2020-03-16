# frozen_string_literal: true

require 'rails_helper'

describe "Changing locales", js: true do
  after { I18n.locale = :en }

  let(:member) { FactoryBot.create :member }
  it "Locale can be set with a query param" do
    # Login then log out, to ensure we're now logged out
    login_as member
    visit root_path
    click_link member.login_name
    click_link 'Sign out'
    expect(page).to have_content("a community of food gardeners.")
    visit root_path(locale: 'ja')
    expect(page).to have_content("はガーデナーのコミュニティです。")
  end
end
