# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "Commenting on Plantings", type: :feature, js: true do
  let(:planting_owner) { FactoryBot.create(:member, login_name: "PlantingOwner") }
  let(:commenter) { FactoryBot.create(:member, login_name: "Commenter") }
  let(:other_member) { FactoryBot.create(:member, login_name: "OtherMember") }
  let(:admin) { FactoryBot.create(:member, :admin, login_name: "AdminUser") }

  # Ensure crop and garden are created for the planting
  let(:crop) { FactoryBot.create(:crop) }
  let(:garden) { FactoryBot.create(:garden, owner: planting_owner) }
  let!(:planting) { FactoryBot.create(:planting, owner: planting_owner, crop: crop, garden: garden, description: "My test planting") }

  def login_as(user)
    visit new_member_session_path
    fill_in "Login Name or Email", with: user.login_name
    fill_in "Password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")
  end

  describe "User comments on a Planting" do
    before do
      login_as(commenter)
      visit planting_path(planting)
    end

    it "allows a user to create a comment" do
      expect(page).to have_content("Comments")
      click_link "Add Comment"

      expect(page).to have_current_path(new_planting_comment_path(planting))
      expect(page).to have_content("Add comment to planting")

      fill_in "comment_body", with: "This planting looks great!"
      click_button "Post comment"

      expect(page).to have_current_path(planting_path(planting))
      expect(page).to have_content("This planting looks great!")
      expect(page).to have_content(commenter.login_name)
    end
  end

  describe "Editing comments on a Planting" do
    let!(:comment_to_edit) { FactoryBot.create(:comment, commentable: planting, author: commenter, body: "Initial planting comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit planting_path(planting)
        find('.comment-body', text: "Initial planting comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows the author to edit their comment" do
        expect(page).to have_current_path(edit_comment_path(comment_to_edit))
        fill_in "comment_body", with: "Updated planting comment."
        click_button "Post comment"

        expect(page).to have_current_path(planting_path(planting))
        expect(page).to have_content("Updated planting comment.")
        expect(page).not_to have_content("Initial planting comment")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit planting_path(planting)
        find('.comment-body', text: "Initial planting comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows admin to edit any comment" do
        fill_in "comment_body", with: "Admin edited this planting comment."
        click_button "Post comment"
        expect(page).to have_content("Admin edited this planting comment.")
      end
    end

    context "as unauthorized user" do
      before do
        login_as(other_member)
        visit planting_path(planting)
      end

      it "does not show edit link for other's comment" do
        comment_element = find('.comment-body', text: "Initial planting comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Edit")
        expect(comment_element).not_to have_button("Actions")
      end
    end
  end

  describe "Deleting comments on a Planting" do
    let!(:comment_to_delete) { FactoryBot.create(:comment, commentable: planting, author: commenter, body: "Delete this planting comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit planting_path(planting)
        find('.comment-body', text: "Delete this planting comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the author to delete their comment" do
        expect(page).not_to have_content("Delete this planting comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as planting owner" do
      before do
        login_as(planting_owner)
        visit planting_path(planting)
        find('.comment-body', text: "Delete this planting comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the planting owner to delete any comment on their planting" do
        expect(page).not_to have_content("Delete this planting comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end
    
    context "as admin" do
      before do
        login_as(admin)
        visit planting_path(planting)
        find('.comment-body', text: "Delete this planting comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows admin to delete any comment" do
        expect(page).not_to have_content("Delete this planting comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as unauthorized user" do
      let!(:another_comment) { FactoryBot.create(:comment, commentable: planting, author: planting_owner, body: "Planting owner's comment") }
      before do
        login_as(other_member)
        visit planting_path(planting)
      end

      it "does not show delete link for other's comment" do
        comment_element = find('.comment-body', text: "Planting owner's comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Delete")
        
        comment_element_2 = find('.comment-body', text: "Delete this planting comment").ancestor('.comment')
        expect(comment_element_2).not_to have_link("Delete")
      end
    end
  end
end
