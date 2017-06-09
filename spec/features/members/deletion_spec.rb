require 'rails_helper'

feature "member deletion" do
  context "with activity and followers" do
    let(:member) { FactoryGirl.create(:member) }
    let(:other_member) { FactoryGirl.create(:member) }
    let(:memberpost) { FactoryGirl.create(:post, author: member) }
    let(:othermemberpost) { FactoryGirl.create(:post, author: other_member) }
    let!(:planting) { FactoryGirl.create(:planting, owner: member) }
    let!(:harvest) { FactoryGirl.create(:harvest, owner: member) }
    let!(:seed) { FactoryGirl.create(:seed, owner: member) }
    let!(:secondgarden) { FactoryGirl.create(:garden, owner: member) }
    let!(:order) { FactoryGirl.create(:order, member: member, completed_at: Time.zone.now) }
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
      FactoryGirl.create(:comment, author: member, post: othermemberpost)
      FactoryGirl.create(:comment, author: other_member, post: memberpost, body: "Fun comment-y thing")
      # deletion breaks if no wranglers exist
      FactoryGirl.create(:cropbot)
      # deletion breaks if ex_member doesn't exist
      FactoryGirl.create(:member, login_name: "ex_member")
    end

    scenario "has option to delete on member profile page" do
      visit member_path(member)
      click_link 'Edit profile'
      expect(page).to have_link "Delete Account"
    end

    scenario "asks for password before deletion" do
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      click_button "Delete"
      expect(page).to have_content "Current password can't be blank"
    end

    scenario "password must be correct" do
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      fill_in "current_pw_for_delete", with: "wrongpassword"
      click_button "Delete"
      expect(page).to have_content "Current password is invalid"
    end

    scenario "deletes and removes bio" do
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      fill_in "current_pw_for_delete", with: "password1", match: :prefer_exact
      click_button "Delete"
      visit member_path(member)
      expect(page.status_code).to eq(404)
    end

    context "deletes and" do
      background do
        logout
        login_as(member)
        visit member_path(member)
        click_link 'Edit profile'
        click_link 'Delete Account'
        fill_in "current_pw_for_delete", with: "password1", match: :prefer_exact
        click_button "Delete"
        logout
      end

      scenario "removes plantings" do
        visit planting_path(planting)
        expect(page.status_code).to eq(404)
      end

      scenario "removes gardens" do
        visit garden_path(secondgarden)
        expect(page.status_code).to eq(404)
      end

      scenario "removes harvests and seeds" do
        visit harvest_path(harvest)
        expect(page.status_code).to eq(404)
      end

      scenario "removes seeds" do
        visit seed_path(seed)
        expect(page.status_code).to eq(404)
      end

      scenario "removes members from following" do
        visit member_follows_path(other_member)
        expect(page).not_to have_content member.login_name.to_s
        visit member_followers_path(other_member)
        expect(page).not_to have_content member.login_name.to_s
      end

      scenario "replaces posts with deletion note" do
        visit post_path(memberpost)
        expect(page.status_code).to eq(404)
      end

      scenario "replaces comments on others' posts with deletion note, leaving post intact" do
        visit post_path(othermemberpost)
        expect(page).not_to have_content member.login_name
        expect(page).to have_content other_member.login_name
        expect(page).to have_content "Member Deleted"
      end

      scenario "leaves a record of orders and payments intact" do
        login_as(admin)
        visit admin_path
        fill_in "search_text", with: member.login_name.to_s
        find("#maincontainer").click_button("Search", exact: true)
        expect(page).to have_content member.login_name.to_s
        expect(page).to have_content "Found 1 result"
        logout
      end

      scenario "can't be interesting" do
        expect(Member.interesting).not_to include(member)
        expect(Planting.interesting).not_to include(planting)
        expect(Seed.interesting).not_to include(seed)
      end

      pending "doesn't show in nearby"

      pending "removed from newsletter"

      scenario "can no longer sign in" do
        visit new_member_session_path
        fill_in 'Login', with: member.login_name
        fill_in 'Password', with: member.password
        click_button 'Sign in'
        expect(page).to have_content 'Invalid Login or password'
      end
    end
  end

  context "for a crop wrangler" do
    let(:member) { FactoryGirl.create(:crop_wrangling_member) }
    let(:otherwrangler) { FactoryGirl.create(:crop_wrangling_member) }
    let(:crop) { FactoryGirl.create(:crop, creator: member) }
    FactoryGirl.create(:cropbot)
    let!(:ex_wrangler) { FactoryGirl.create(:crop_wrangling_member, login_name: "ex_wrangler") }

    scenario "leaves crops behind, reassigned to ex_wrangler" do
      login_as(otherwrangler)
      visit edit_crop_path(crop)
      expect(page).to have_content member.login_name.to_s
      expect(page).not_to have_content "cropbot"
      logout
      login_as(member)
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      fill_in "current_pw_for_delete", with: "password1", match: :prefer_exact
      click_button "Delete"
      login_as(otherwrangler)
      visit edit_crop_path(crop)
      expect(page).not_to have_content member.login_name.to_s
    end
  end

  context "for an admin" do
    let(:member) { FactoryGirl.create(:admin_member) }
    let(:crop) { FactoryGirl.create(:crop, creator: member) }

    scenario "leaves crops behind, reassigned to cropbot"

    scenario "leaves forums behind, reassigned to ex_admin"
  end
end
