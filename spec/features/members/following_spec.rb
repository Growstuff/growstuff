# frozen_string_literal: true

require 'rails_helper'

describe "follows", :js do
  context "when signed out" do
    let(:member) { create :member }

    it "follow buttons on member profile page" do
      visit member_path(member)
      expect(page).not_to have_link "Follow"
      expect(page).not_to have_link "Unfollow"
    end
  end

  context "when signed in" do
    include_context 'signed in member'
    let(:other_member) { create :member }

    it "your profile doesn't have a follow button" do
      visit member_path(member)
      expect(page).not_to have_link "Follow"
      expect(page).not_to have_link "Unfollow"
    end

    context "following another member" do
      before { visit member_path(other_member) }

      it "has a follow button" do
        expect(page).to have_link "Follow", href: follows_path(followed: other_member.slug)
      end

      it "has correct message and unfollow button" do
        click_link 'Follow'
        expect(page).to have_content "Followed #{other_member.login_name}"
        expect(page).to have_link "Unfollow", href: follow_path(member.get_follow(other_member))
      end

      it "has a followed member listed in the following page" do
        click_link 'Follow'
        visit member_follows_path(member)
        expect(page).to have_content other_member.login_name
      end

      it "has correct message and follow button after unfollow" do
        click_link 'Follow'
        click_link 'Unfollow'
        expect(page).to have_content "Unfollowed #{other_member.login_name}"
        visit member_path(other_member) # unfollowing redirects to root
        expect(page).to have_link "Follow", href: follows_path(followed: other_member.slug)
      end

      it "has member in following list" do
        click_link 'Follow'
        visit member_follows_path(member)
        expect(page).to have_content other_member.login_name
      end

      it "appears in in followed member's followers list" do
        click_link 'Follow'
        visit member_followers_path(other_member)
        expect(page).to have_content member.login_name
      end

      it "removes members from following and followers lists after unfollow" do
        click_link 'Follow'
        click_link 'Unfollow'
        visit member_follows_path(member)
        expect(page).not_to have_content other_member.login_name
        visit member_followers_path(other_member)
        expect(page).to have_content member.login_name
      end
    end
  end
end
