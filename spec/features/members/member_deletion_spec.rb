require 'rails_helper'

feature "member deletion" do

  context "member with activity and follows" do
    let(:member) { FactoryGirl.create(:member) }
    let(:other_member) { FactoryGirl.create(:member) }
    background do
        login_as(member)
        visit member_path(other_member)
        click_link 'Follow'
        logout
        login_as(other_member)
        visit member_path(member)
        click_link 'Follow'
        logout
        FactoryGirl.create_list(:planting, 2, :owner => member)
        FactoryGirl.create_list(:harvest, 3, :owner => member)
        FactoryGirl.create_list(:seed, 4, :owner => member)
        FactoryGirl.create_list(:post, 5, :author => member)
      end

    scenario "option to delete on member profile page" do
      visit member_path(member)
      expect(page).to have_link "Delete account", :href => member_delete_path(member)
    end

    scenario "delete" do
      member.delete
      member.save
      visit member_path(member)
      expect(page).to have_content "no longer exists"
    end

    scenario "removes members from following" do
      visit member_follows_path(other_member)
      expect(page).not_to have_content "#{member.login_name}"
      visit member_followers_path(other_member)
      expect(page).not_to have_content "#{member.login_name}"
    end

  end
end
