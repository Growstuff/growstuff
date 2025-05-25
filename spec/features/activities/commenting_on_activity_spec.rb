# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "Commenting on Activities", type: :feature, js: true do
  let(:activity_owner) { FactoryBot.create(:member, login_name: "ActivityOwner") }
  let(:commenter) { FactoryBot.create(:member, login_name: "Commenter") }
  let(:other_member) { FactoryBot.create(:member, login_name: "OtherMember") }
  let(:admin) { FactoryBot.create(:member, :admin, login_name: "AdminUser") }

  let!(:activity) { FactoryBot.create(:activity, owner: activity_owner, name: "Gardening Day") }


  def login_as(user)
    visit new_member_session_path
    fill_in "Login Name or Email", with: user.login_name
    fill_in "Password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")
  end

  describe "User comments on an Activity" do
    before do
      login_as(commenter)
      visit activity_path(activity)
    end

    it "allows a user to create a comment" do
      expect(page).to have_content("Comments")
      click_link "Add Comment"

      expect(page).to have_current_path(new_activity_comment_path(activity))
      expect(page).to have_content("Add comment to activity")

      fill_in "comment_body", with: "Sounds like a fun activity!"
      click_button "Post comment"

      expect(page).to have_current_path(activity_path(activity))
      expect(page).to have_content("Sounds like a fun activity!")
      expect(page).to have_content(commenter.login_name)
    end
  end

  describe "Editing comments on an Activity" do
    let!(:comment_to_edit) { FactoryBot.create(:comment, commentable: activity, author: commenter, body: "Initial activity comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit activity_path(activity)
        find('.comment-body', text: "Initial activity comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows the author to edit their comment" do
        expect(page).to have_current_path(edit_comment_path(comment_to_edit))
        fill_in "comment_body", with: "Updated activity comment."
        click_button "Post comment"

        expect(page).to have_current_path(activity_path(activity))
        expect(page).to have_content("Updated activity comment.")
        expect(page).not_to have_content("Initial activity comment")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit activity_path(activity)
        find('.comment-body', text: "Initial activity comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows admin to edit any comment" do
        fill_in "comment_body", with: "Admin edited this activity comment."
        click_button "Post comment"
        expect(page).to have_content("Admin edited this activity comment.")
      end
    end

    context "as unauthorized user" do
      before do
        login_as(other_member)
        visit activity_path(activity)
      end

      it "does not show edit link for other's comment" do
        comment_element = find('.comment-body', text: "Initial activity comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Edit")
        expect(comment_element).not_to have_button("Actions")
      end
    end
  end

  describe "Deleting comments on an Activity" do
    let!(:comment_to_delete) { FactoryBot.create(:comment, commentable: activity, author: commenter, body: "Delete this activity comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit activity_path(activity)
        find('.comment-body', text: "Delete this activity comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the author to delete their comment" do
        expect(page).not_to have_content("Delete this activity comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as activity owner" do
      before do
        login_as(activity_owner)
        visit activity_path(activity)
        find('.comment-body', text: "Delete this activity comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the activity owner to delete any comment on their activity" do
        expect(page).not_to have_content("Delete this activity comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit activity_path(activity)
        find('.comment-body', text: "Delete this activity comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows admin to delete any comment" do
        expect(page).not_to have_content("Delete this activity comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as unauthorized user" do
      let!(:another_comment) { FactoryBot.create(:comment, commentable: activity, author: activity_owner, body: "Activity owner's comment") }
      before do
        login_as(other_member)
        visit activity_path(activity)
      end

      it "does not show delete link for other's comment" do
        comment_element = find('.comment-body', text: "Activity owner's comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Delete")
        
        comment_element_2 = find('.comment-body', text: "Delete this activity comment").ancestor('.comment')
        expect(comment_element_2).not_to have_link("Delete")
      end
    end
  end
end
