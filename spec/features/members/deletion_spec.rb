require 'rails_helper'

feature "member deletion" do
  context "with activity and followers" do
    let(:member) { FactoryBot.create(:member) }
    let(:other_member) { FactoryBot.create(:member) }
    let(:memberpost) { FactoryBot.create(:post, author: member) }
    let(:othermemberpost) { FactoryBot.create(:post, author: other_member) }
    let!(:planting) { FactoryBot.create(:planting, owner: member) }
    let!(:harvest) { FactoryBot.create(:harvest, owner: member) }
    let!(:seed) { FactoryBot.create(:seed, owner: member) }
    let!(:secondgarden) { FactoryBot.create(:garden, owner: member) }
    let(:admin) { FactoryBot.create(:admin_member) }

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
      FactoryBot.create(:comment, author: member, post: othermemberpost)
      FactoryBot.create(:comment, author: other_member, post: memberpost, body: "Fun comment-y thing")
      # deletion breaks if no wranglers exist
      FactoryBot.create(:cropbot)
      # deletion breaks if ex_member doesn't exist
      FactoryBot.create(:member, login_name: "ex_member")
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

      scenario "can't be interesting" do
        expect(Member.interesting).not_to include(member)
        expect(Planting.interesting).not_to include(planting)
        expect(Seed.interesting).not_to include(seed)
      end

      pending "doesn't show in nearby"

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
    let(:member) { FactoryBot.create(:crop_wrangling_member) }
    let(:otherwrangler) { FactoryBot.create(:crop_wrangling_member) }
    let(:crop) { FactoryBot.create(:crop, creator: member) }
    FactoryBot.create(:cropbot)
    let!(:ex_wrangler) { FactoryBot.create(:crop_wrangling_member, login_name: "ex_wrangler") }

    scenario "leaves crops behind" do
      login_as(otherwrangler)
      visit edit_crop_path(crop)
      expect(page).to have_content member.login_name
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
      expect(page).not_to have_content member.login_name
    end
  end
end
