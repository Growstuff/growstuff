require 'rails_helper'

feature "member deletion" do

  context "with activity and followers" do
    let(:member) { FactoryGirl.create(:member) }
    let(:other_member) { FactoryGirl.create(:member) }
    let(:memberpost) { FactoryGirl.create(:post, :author => member) }
    let(:othermemberpost) { FactoryGirl.create(:post, :author => other_member) }
    let(:planting) { FactoryGirl.create(:planting, :owner => member) }
    let(:harvest) { FactoryGirl.create(:harvest, :owner => member) }
    let(:seed) { FactoryGirl.create(:seed, :owner => member) }
    let(:secondgarden) { FactoryGirl.create(:garden, :owner => member) }
    let(:order) { FactoryGirl.create(:order, :belongs_to => member) }
    let(:admin) { FactoryGirl.create(:admin_member) }
    background do
      login_as(member)
      visit member_path(other_member)
      click_link 'Follow'
      logout
      login_as(other_member)
      visit member_path(member)
      click_link 'Follow'
      logout
      login_as(member)
      FactoryGirl.create(:comment, :author => member, :post => othermemberpost)
      FactoryGirl.create(:comment, :author => other_member, :post => memberpost, :body => "Fun comment-y thing")
      # deletion breaks if no wranglers exist
      FactoryGirl.create(:cropbot)
      # deletion breaks if ex_member doesn't exist
      FactoryGirl.create(:member, :login_name => "ex_member")
    end

    scenario "has option to delete on member profile page" do
      visit member_path(member)
      expect(page).to have_link "Delete account"
    end

    scenario "asks for password before deletion" do
      visit member_path(member)
      click_link 'Delete account'
      click_link 'Delete your account'
      click_button "Delete"
      expect(page).to have_content "Current password can't be blank"
    end
    
    scenario "password must be correct" do
      visit member_path(member)
      click_link 'Delete account'
      click_link 'Delete your account'
      fill_in "current_pw_for_delete", :with => "wrongpassword"
      click_button "Delete"
      expect(page).to have_content "Current password is invalid"
    end

    scenario "deletes and removes bio" do
      visit member_path(member)
      click_link 'Delete account'
      click_link 'Delete your account'
      fill_in "current_pw_for_delete", :with => "password1", :match => :prefer_exact
      click_button "Delete"
      expect(page).to have_content "Member marked as deleted"
      visit member_path(member)
      # Once we get proper 404s, this will change to something friendlier
      # Currently it is the ActiveRecord error page
      expect(page).to have_content "NotFound"
    end
    
    context "deletes and" do
      background do
        logout
        login_as(member)
        visit member_path(member)
        click_link 'Delete account'
        click_link 'Delete your account'
        fill_in "current_pw_for_delete", :with => "password1", :match => :prefer_exact
        click_button "Delete"
        logout
      end

      scenario "removes plantings" do
        visit planting_path(planting)
        expect(page).not_to have_content "#{member.login_name}"
        expect(page).to have_content "ex_member"
      end

      scenario "removes gardens" do
        visit garden_path(secondgarden)
        expect(page).to have_content "ex_member"
        expect(page).not_to have_content "#{member.login_name}"
      end

      scenario "removes harvests and seeds" do
        visit harvest_path(harvest)
        expect(page).not_to have_content "#{member.login_name}"
        expect(page).to have_content "ex_member"
        visit seed_path(seed)
        expect(page).not_to have_content "#{member.login_name}"
        expect(page).to have_content "ex_member"
      end

      scenario "removes members from following" do
        visit member_follows_path(other_member)
        expect(page).not_to have_content "#{member.login_name}"
        visit member_followers_path(other_member)
        expect(page).not_to have_content "#{member.login_name}"
      end
    
      scenario "replaces posts with deletion note" do
        visit post_path(memberpost)
        expect(page).not_to have_content "#{member.login_name}"
        expect(page).to have_content "This post was removed as the author deleted their account."
      end

      scenario "leaves comments from other members on deleted post" do
        visit post_path(memberpost)
        expect(page).to have_content "#{other_member.login_name}"
        expect(page).to have_content "Fun comment-y thing"
      end

      scenario "replaces comments on others' posts with deletion note, leaving post intact" do
        visit post_path(othermemberpost)
        expect(page).to have_content "#{other_member.login_name}"
        expect(page).not_to have_content "#{member.login_name}"
        expect(page).to have_content "This comment was removed as the author deleted their account."
      end

      scenario "leaves a record of orders and payments intact" do
        login_as(admin)
        visit admin_path
        fill_in "search_text", :with => "#{member.login_name}"
        find("#maincontainer").click_button("Search", exact: true)
        expect(page).to have_content "#{member.login_name}"
        expect(page).to have_content "Found 1 result"
        logout
      end

      scenario "can't be interesting"

      scenario "doesn't show in nearby"

      scenario "removed from newsletter"

      scenario "can no longer sign in"

    end
    
  end
  
  context "for a crop wrangler" do
    let(:member) { FactoryGirl.create(:crop_wrangling_member) }
    let(:otherwrangler) { FactoryGirl.create(:crop_wrangling_member) }
    let(:crop) { FactoryGirl.create(:crop, :creator => member) }
    FactoryGirl.create(:cropbot)
    let!(:ex_wrangler) { FactoryGirl.create(:crop_wrangling_member, :login_name => "ex_wrangler") }

    scenario "leaves crops behind, reassigned to ex_wrangler" do
      login_as(otherwrangler)
      visit edit_crop_path(crop)
      expect(page).to have_content "#{member.login_name}"
      expect(page).not_to have_content "cropbot"
      expect(page).not_to have_content "ex_wrangler"
      logout
      login_as(member)
      visit member_path(member)
      click_link 'Delete account'
      click_link 'Delete your account'
      fill_in "current_pw_for_delete", :with => "password1", :match => :prefer_exact
      click_button "Delete"
      login_as(otherwrangler)
      visit edit_crop_path(crop)
      expect(page).not_to have_content "#{member.login_name}"
      expect(page).to have_content "ex_wrangler"
    end
    
  end
  
  context "for an admin" do
    let(:member) { FactoryGirl.create(:admin_member) }
    let(:crop) { FactoryGirl.create(:crop, :creator => member) }
    
    scenario "leaves crops behind, reassigned to cropbot"
    
    scenario "leaves forums behind, reassigned to ex_admin"
    
  end
  
end
