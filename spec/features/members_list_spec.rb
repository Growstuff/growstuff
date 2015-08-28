require 'rails_helper'

feature "members list" do
  context "list all members" do
    let!(:member1) { create :member, login_name: "Archaeopteryx", confirmed_at: Time.zone.parse('2013-02-10') }
    let!(:member2) { create :member, login_name: "Zephyrosaurus", confirmed_at: Time.zone.parse('2014-01-11') }
    let!(:member3) { create :member, login_name: "Testingname", confirmed_at: Time.zone.parse('2014-05-09') }

    scenario "default alphabetical sort" do
      visit members_path
      expect(page).to have_css "#sort"
      expect(page).to have_selector "form"
      click_button('Show')
      all_links = page.all("#maincontainer p.login-name")
      expect(all_links.first).to have_text member1.login_name
      expect(all_links.last).to have_text member2.login_name
    end

    scenario "recently joined sort" do
      visit members_path
      expect(page).to have_css "#sort"
      expect(page).to have_selector "form"
      select("recently", :from => 'sort')
      click_button('Show')
      all_links = page.all("#maincontainer p.login-name")
      expect(all_links.first).to have_text member3.login_name
      expect(all_links.last).to have_text member1.login_name
    end
  end
end