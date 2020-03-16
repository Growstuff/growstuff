# frozen_string_literal: true

require 'rails_helper'

describe "members list" do
  context "list all members" do
    let!(:member1) { create :member, login_name: "Archaeopteryx", confirmed_at: Time.zone.parse('2013-02-10') }
    let!(:member2) { create :member, login_name: "Zephyrosaurus", confirmed_at: Time.zone.parse('2014-01-11') }
    let!(:member3) { create :member, login_name: "Testingname", confirmed_at: Time.zone.parse('2014-05-09')   }

    subject { page.all("#maincontainer h4.login-name") }

    before do
      visit members_path
      expect(page).to have_css "#sort"
      expect(page).to have_selector "form"
    end

    it "default alphabetical sort" do
      click_button('Show')
      expect(subject.first).to have_text member1.login_name
      expect(subject.last).to have_text member2.login_name
    end

    it "recently joined sort" do
      select("recently", from: 'sort')
      click_button('Show')
      expect(subject.first).to have_text member3.login_name
      expect(subject.last).to have_text member1.login_name
    end
  end
end
