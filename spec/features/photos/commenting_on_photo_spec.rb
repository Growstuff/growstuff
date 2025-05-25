# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "Commenting on Photos", type: :feature, js: true do
  let(:photo_owner) { FactoryBot.create(:member, login_name: "PhotoOwner") }
  let(:commenter) { FactoryBot.create(:member, login_name: "Commenter") }
  let(:other_member) { FactoryBot.create(:member, login_name: "OtherMember") }
  let(:admin) { FactoryBot.create(:member, :admin, login_name: "AdminUser") }

  let!(:photo) { FactoryBot.create(:photo, owner: photo_owner, title: "Beautiful Sunset") }

  def login_as(user)
    visit new_member_session_path
    fill_in "Login Name or Email", with: user.login_name
    fill_in "Password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")
  end

  describe "User comments on a Photo" do
    before do
      login_as(commenter)
      visit photo_path(photo)
    end

    it "allows a user to create a comment" do
      expect(page).to have_content("Comments")
      click_link "Add Comment" # From the _comments partial

      expect(page).to have_current_path(new_photo_comment_path(photo))
      expect(page).to have_content("Add comment to photo")

      fill_in "comment_body", with: "What a stunning photo!"
      click_button "Post comment"

      expect(page).to have_current_path(photo_path(photo))
      expect(page).to have_content("What a stunning photo!")
      expect(page).to have_content(commenter.login_name)
    end
  end

  describe "Editing comments on a Photo" do
    let!(:comment_to_edit) { FactoryBot.create(:comment, commentable: photo, author: commenter, body: "Initial comment body") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit photo_path(photo)
        # Find the comment section and then the edit button within it.
        # This assumes the comment body is unique enough or we can find by specific data-testid attributes if added.
        find('.comment-body', text: "Initial comment body").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows the author to edit their comment" do
        expect(page).to have_current_path(edit_comment_path(comment_to_edit))
        fill_in "comment_body", with: "Updated comment body here."
        click_button "Post comment"

        expect(page).to have_current_path(photo_path(photo))
        expect(page).to have_content("Updated comment body here.")
        expect(page).not_to have_content("Initial comment body")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit photo_path(photo)
        find('.comment-body', text: "Initial comment body").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows admin to edit any comment" do
        fill_in "comment_body", with: "Admin edited this comment."
        click_button "Post comment"
        expect(page).to have_content("Admin edited this comment.")
      end
    end

    context "as unauthorized user" do
      before do
        login_as(other_member)
        visit photo_path(photo)
      end

      it "does not show edit link for other's comment" do
        # Check within the specific comment's scope
        comment_element = find('.comment-body', text: "Initial comment body").ancestor('.comment')
        expect(comment_element).not_to have_link("Edit")
        expect(comment_element).not_to have_button("Actions") # Or check that Actions doesn't show Edit
      end
    end
  end

  describe "Deleting comments on a Photo" do
    let!(:comment_to_delete) { FactoryBot.create(:comment, commentable: photo, author: commenter, body: "This will be deleted") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit photo_path(photo)
        find('.comment-body', text: "This will be deleted").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the author to delete their comment" do
        expect(page).not_to have_content("This will be deleted")
        expect(page).to have_content("Comment was successfully destroyed.") # Assuming flash message
      end
    end

    context "as photo owner" do
      before do
        login_as(photo_owner)
        visit photo_path(photo)
        find('.comment-body', text: "This will be deleted").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the photo owner to delete any comment on their photo" do
        expect(page).not_to have_content("This will be deleted")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end
    
    context "as admin" do
      before do
        login_as(admin)
        visit photo_path(photo)
        find('.comment-body', text: "This will be deleted").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows admin to delete any comment" do
        expect(page).not_to have_content("This will be deleted")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as unauthorized user" do
      let!(:another_comment) { FactoryBot.create(:comment, commentable: photo, author: photo_owner, body: "Photo owner's comment") }
      before do
        login_as(other_member) # other_member is not admin, not photo_owner, not author of `another_comment`
        visit photo_path(photo)
      end

      it "does not show delete link for other's comment" do
        comment_element = find('.comment-body', text: "Photo owner's comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Delete")
        # Also check the original comment_to_delete by commenter
        comment_element_2 = find('.comment-body', text: "This will be deleted").ancestor('.comment')
        expect(comment_element_2).not_to have_link("Delete")
      end
    end
  end
end
