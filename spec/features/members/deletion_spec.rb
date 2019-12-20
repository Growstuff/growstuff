# frozen_string_literal: true

require 'rails_helper'

describe "member deletion" do
  context "with activity and followers" do
    let(:member)          { FactoryBot.create(:member)                     }
    let(:other_member)    { FactoryBot.create(:member)                     }
    let(:memberpost)      { FactoryBot.create(:post, author: member)       }
    let(:othermemberpost) { FactoryBot.create(:post, author: other_member) }
    let!(:planting)       { FactoryBot.create(:planting, owner: member)    }
    let!(:harvest)        { FactoryBot.create(:harvest, owner: member)     }
    let!(:seed)           { FactoryBot.create(:seed, owner: member)        }
    let!(:secondgarden)   { FactoryBot.create(:garden, owner: member)      }

    before do
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

    it "has option to delete on member profile page" do
      visit member_path(member)
      click_link 'Edit profile'
      expect(page).to have_link "Delete Account"
    end

    it "asks for password before deletion" do
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      click_button "Delete"
      expect(page).to have_content "Incorrect password"
    end

    it "password must be correct" do
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      fill_in "current_pw_for_delete", with: "wrongpassword"
      click_button "Delete"
      expect(page).to have_content "Incorrect password"
    end

    it "deletes and removes bio" do
      visit member_path(member)
      click_link 'Edit profile'
      click_link 'Delete Account'
      fill_in "current_pw_for_delete", with: "password1", match: :prefer_exact
      click_button "Delete"
      visit member_path(member)
      expect(page).to have_text "The page you were looking for doesn't exist."
    end

    describe 'percy spec' do
      it do
        logout
        login_as(member)
        visit member_path(member)
        click_link 'Edit profile'
        click_link 'Delete Account'
        Percy.snapshot(page, name: 'Account deletion')
      end
    end

    context "deletes and" do
      before do
        logout
        login_as(member)
        visit member_path(member)
        click_link 'Edit profile'
        click_link 'Delete Account'
        fill_in "current_pw_for_delete", with: "password1", match: :prefer_exact
        click_button "Delete"
        logout
      end

      describe 'member exists but is marked deleted' do
        subject { Member.all.find(member.id) }
        it { expect(subject).to eq member }
        it { expect(subject.discarded?).to eq true }
        it { expect(Member.kept).not_to include(member) }
      end

      it "removes plantings" do
        visit planting_path(planting)
        expect(page).to have_text "The page you were looking for doesn't exist."
      end

      it "removes gardens" do
        visit garden_path(secondgarden)
        expect(page).to have_text "The page you were looking for doesn't exist."
      end

      it "removes harvests and seeds" do
        visit harvest_path(harvest)
        expect(page).to have_text "The page you were looking for doesn't exist."
      end

      it "removes seeds" do
        visit seed_path(seed)
        expect(page).to have_text "The page you were looking for doesn't exist."
      end

      it "removes members from following" do
        visit member_follows_path(other_member)
        expect(page).not_to have_content member.login_name.to_s
        visit member_followers_path(other_member)
        expect(page).not_to have_content member.login_name.to_s
      end

      it "replaces posts with deletion note" do
        visit post_path(memberpost)
        expect(page).to have_text "The page you were looking for doesn't exist."
      end

      it "replaces comments on others' posts with deletion note, leaving post intact" do
        FactoryBot.create :comment, post: othermemberpost, author: member, body: 'i am deleting my account'

        visit post_path(othermemberpost)
        expect(page).not_to have_content member.login_name
        expect(page).to have_content other_member.login_name
        expect(page).to have_content "Member Deleted"
      end

      it "can't be interesting" do
        expect(Member.interesting).not_to include(member)
        expect(Planting.interesting).not_to include(planting)
        expect(Seed.interesting).not_to include(seed)
      end

      pending "doesn't show in nearby"

      it "can no longer sign in" do
        visit new_member_session_path
        fill_in 'Login', with: member.login_name
        fill_in 'Password', with: member.password
        click_button 'Sign in'
        expect(page).to have_content 'Your account is not activated'
      end
    end
  end

  context "for a crop wrangler" do
    let(:member) { FactoryBot.create(:crop_wrangling_member) }
    let(:otherwrangler) { FactoryBot.create(:crop_wrangling_member) }
    let(:crop)          { FactoryBot.create(:crop, creator: member) }
    before { FactoryBot.create(:cropbot) }
    let!(:ex_wrangler) { FactoryBot.create(:crop_wrangling_member, login_name: "ex_wrangler") }

    it "leaves crops behind" do
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
