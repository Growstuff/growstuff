# frozen_string_literal: true

require 'rails_helper'

describe "members list" do
  context "list all members" do
    subject { page.all("#maincontainer h4.login-name") }

    let!(:archaeopteryx) { create(:member, login_name: "Archaeopteryx", confirmed_at: Time.zone.parse('2013-02-10')) }
    let!(:zephyrosaurus) { create(:member, login_name: "Zephyrosaurus", confirmed_at: Time.zone.parse('2014-01-11')) }
    let!(:testingname)   { create(:member, login_name: "Testingname", confirmed_at: Time.zone.parse('2014-05-09'))   }

    before do
      visit members_path
    end

    it "default alphabetical sort" do
      expect(page).to have_css "#sort"
      expect(page).to have_css "form"
      click_button('Show')
      expect(subject.first).to have_text archaeopteryx.login_name
      expect(subject.last).to have_text zephyrosaurus.login_name
    end

    it "recently joined sort" do
      expect(page).to have_css "#sort"
      expect(page).to have_css "form"
      select("recently", from: 'sort')
      click_button('Show')
      expect(subject.first).to have_text testingname.login_name
      expect(subject.last).to have_text archaeopteryx.login_name
    end
  end
end
