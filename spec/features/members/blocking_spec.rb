# frozen_string_literal: true

require 'rails_helper'

describe "blocks", :js do
  context "when signed in" do
    include_context 'signed in member'
    let(:other_member) { create(:member) }

    it "your profile doesn't have a block button" do
      visit member_path(member)
      expect(page).to have_no_link "Block"
      expect(page).to have_no_link "Unblock"
    end

    context "blocking another member" do
      before { visit member_path(other_member) }

      it "has a block button" do
        expect(page).to have_link "Block", href: blocks_path(blocked: other_member.slug)
      end

      it "has correct message and unblock button" do
        click_link 'Block'
        expect(page).to have_content "Blocked #{other_member.login_name}"
        expect(page).to have_link "Unblock", href: block_path(member.get_block(other_member))
      end

      it "has correct message and block button after unblock" do
        click_link 'Block'
        click_link 'Unblock'
        expect(page).to have_content "Unblocked #{other_member.login_name}"
        visit member_path(other_member) # unblocking redirects to root
        expect(page).to have_link "Block", href: blocks_path(blocked: other_member.slug)
      end

      context "when a member is blocked" do
        before do
          click_link 'Block'
        end

        it "prevents following" do
          visit member_path(other_member)
          expect(page).to have_no_link "Follow"
        end

        it "prevents messaging" do
          visit new_message_path(recipient_id: other_member.id)
          fill_in "Subject", with: "Test message"
          fill_in "Body", with: "Test message body"
          click_button "Send message"
          expect(page).to have_content "You cannot send a message to a member who has blocked you."
        end

        it "prevents commenting" do
          post = create(:post, author: other_member)
          visit post_path(post)
          fill_in "comment_body", with: "Test comment"
          click_button "Post Comment"
          expect(page).to have_content "You cannot comment on a post of a member who has blocked you."
        end

        it "prevents liking" do
          post = create(:post, author: other_member)
          visit post_path(post)
          click_link "Like"
          expect(page).to have_content "You cannot like content of a member who has blocked you."
        end
      end
    end
  end
end
