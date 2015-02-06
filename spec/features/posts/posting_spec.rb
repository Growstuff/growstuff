require 'rails_helper'

feature "posts", :js => true do

  context "when signed in" do
    let(:member) { FactoryGirl.create(:member) }
    let(:other_member) { FactoryGirl.create(:member) }

    background do
      login_as(member)
    end

    scenario "visit new post page" do
      visit new_post_path
      expect(page.status_code).to be 200
      expect(page).to have_content "Post something"
    end

    scenario "post something" do
      visit new_post_path
      within "#new_post" do
        fill_in 'Subject', :with => "Garden status"
        fill_in "What's going on in your food garden?", :with => "My garden is great"
        click_button "Post"
      end
      expect(page).to have_content "Post was successfully created"
      expect(page).to have_content "Garden status"
      expect(page).to have_content "My garden is great"
    end

  end
end
