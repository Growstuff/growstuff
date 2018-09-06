require 'rails_helper'

feature "follows", :js do
  context "when signed out" do
    let(:member) { create :member }

    scenario "follow buttons on member profile page" do
      visit member_path(member)
      expect(page).not_to have_link "Follow"
      expect(page).not_to have_link "Unfollow"
    end
  end

  context "when signed in" do
    let(:member) { create :member }
    let(:other_member) { create :member }

    background do
      login_as(member)
    end

    scenario "your profile doesn't have a follow button" do
      visit member_path(member)
      expect(page).not_to have_link "Follow"
      expect(page).not_to have_link "Unfollow"
    end

    context "following another member" do
      background do
        visit member_path(other_member)
      end

      scenario "has a follow button" do
        expect(page).to have_link "Follow", href: follows_path(followed_id: other_member.id)
      end

      scenario "has correct message and unfollow button" do
        click_link 'Follow'
        expect(page).to have_content "Followed #{other_member.login_name}"
        expect(page).to have_link "Unfollow", href: follow_path(member.get_follow(other_member))
      end

      scenario "has a followed member listed in the following page" do
        click_link 'Follow'
        visit member_follows_path(member)
        expect(page).to have_content other_member.login_name.to_s
      end

      scenario "does not die when passed an authenticity_token" do
        visit member_follows_path member, params: { authenticity_token: "Ultima ratio regum" }
        expect(page.status_code).to equal 200
      end

      scenario "has correct message and follow button after unfollow" do
        click_link 'Follow'
        click_link 'Unfollow'
        expect(page).to have_content "Unfollowed #{other_member.login_name}"
        visit member_path(other_member) # unfollowing redirects to root
        expect(page).to have_link "Follow", href: follows_path(followed_id: other_member.id)
      end

      scenario "has member in following list" do
        click_link 'Follow'
        visit member_follows_path(member)
        expect(page).to have_content other_member.login_name.to_s
      end

      scenario "appears in in followed member's followers list" do
        click_link 'Follow'
        visit member_followers_path(other_member)
        expect(page).to have_content member.login_name.to_s
      end

      scenario "removes members from following and followers lists after unfollow" do
        click_link 'Follow'
        click_link 'Unfollow'
        visit member_follows_path(member)
        expect(page).not_to have_content other_member.login_name.to_s
        visit member_followers_path(other_member)
        expect(page).to have_content member.login_name.to_s
      end
    end
  end
end
