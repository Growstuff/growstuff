# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "Commenting on Posts", type: :feature, js: true do
  # Use existing 'signed in member' shared context if it provides Capybara login helper
  # Otherwise, define one locally or ensure one is available.
  # For consistency with other new specs, defining a local login_as helper.
  let(:post_author) { FactoryBot.create(:member, login_name: "PostAuthor") }
  let(:commenter) { FactoryBot.create(:member, login_name: "Commenter") }
  let(:other_member) { FactoryBot.create(:member, login_name: "OtherMember") }
  let(:admin) { FactoryBot.create(:member, :admin, login_name: "AdminUser") }

  # Ensure a forum is created for the post if your Post factory/model requires it
  let!(:forum) { FactoryBot.create(:forum) }
  let!(:post) { FactoryBot.create(:post, author: post_author, forum: forum, subject: "My Test Post") }

  def login_as(user)
    visit new_member_session_path
    fill_in "Login Name or Email", with: user.login_name
    fill_in "Password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")
  end

  # Include shared examples for accessibility if they exist and are relevant
  # For now, focusing on the commenting CRUD operations.
  # The original spec had: include_examples 'is accessible'
  # If this shared example exists and is desired, it can be added to relevant `before` blocks.

  describe "User comments on a Post" do
    before do
      login_as(commenter)
      visit post_path(post)
    end

    it "allows a user to create a comment" do
      expect(page).to have_content("Comments") # From the _comments partial
      # The "Add Comment" link is now within the _comments partial
      # If the _comments partial is set up to show the form directly or link to new, this will work.
      # Assuming it has a link:
      click_link "Add Comment" 
      
      expect(page).to have_current_path(new_post_comment_path(post))
      expect(page).to have_content("Add comment to post")

      fill_in "comment_body", with: "This is a great post!"
      click_button "Post comment"

      expect(page).to have_current_path(post_path(post)) # Should redirect back to the post
      expect(page).to have_content("This is a great post!")
      expect(page).to have_content(commenter.login_name)
      # Check for flash message if your controller sets one, e.g.:
      # expect(page).to have_content("Comment was successfully created.")
    end
  end

  describe "Editing comments on a Post" do
    let!(:comment_to_edit) { FactoryBot.create(:comment, commentable: post, author: commenter, body: "Initial post comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit post_path(post)
        find('.comment-body', text: "Initial post comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows the author to edit their comment" do
        expect(page).to have_current_path(edit_comment_path(comment_to_edit))
        fill_in "comment_body", with: "Updated post comment."
        click_button "Post comment"

        expect(page).to have_current_path(post_path(post))
        expect(page).to have_content("Updated post comment.")
        expect(page).not_to have_content("Initial post comment")
        # Check for flash message if your controller sets one, e.g.:
        # expect(page).to have_content("Comment was successfully updated.")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit post_path(post)
        find('.comment-body', text: "Initial post comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows admin to edit any comment" do
        fill_in "comment_body", with: "Admin edited this post comment."
        click_button "Post comment"
        expect(page).to have_content("Admin edited this post comment.")
      end
    end

    context "as unauthorized user" do
      before do
        login_as(other_member)
        visit post_path(post)
      end

      it "does not show edit link for other's comment" do
        comment_element = find('.comment-body', text: "Initial post comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Edit")
        expect(comment_element).not_to have_button("Actions")
      end
    end
  end

  describe "Deleting comments on a Post" do
    let!(:comment_to_delete) { FactoryBot.create(:comment, commentable: post, author: commenter, body: "Delete this post comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit post_path(post)
        find('.comment-body', text: "Delete this post comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the author to delete their comment" do
        expect(page).not_to have_content("Delete this post comment")
        expect(page).to have_content("Comment was successfully destroyed.") # Assuming flash message
      end
    end

    context "as post author (owner of commentable)" do
      before do
        # Ensure commenter is not the post_author for this specific test
        expect(commenter).not_to eq(post_author)
        login_as(post_author)
        visit post_path(post)
        find('.comment-body', text: "Delete this post comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the post author to delete any comment on their post" do
        expect(page).not_to have_content("Delete this post comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end
    
    context "as admin" do
      before do
        login_as(admin)
        visit post_path(post)
        find('.comment-body', text: "Delete this post comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows admin to delete any comment" do
        expect(page).not_to have_content("Delete this post comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as unauthorized user" do
      # Create a comment by the post_author to test against
      let!(:another_comment) { FactoryBot.create(:comment, commentable: post, author: post_author, body: "Post author's comment") }
      before do
        login_as(other_member) # other_member is not admin, not post_author, not author of `another_comment`
        visit post_path(post)
      end

      it "does not show delete link for other's comment" do
        comment_element = find('.comment-body', text: "Post author's comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Delete")
        
        # Also check the original comment_to_delete by commenter
        comment_element_2 = find('.comment-body', text: "Delete this post comment").ancestor('.comment')
        expect(comment_element_2).not_to have_link("Delete")
      end
    end
  end
end
