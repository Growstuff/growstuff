# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "Commenting on Harvests", type: :feature, js: true do
  let(:harvest_owner) { FactoryBot.create(:member, login_name: "HarvestOwner") }
  let(:commenter) { FactoryBot.create(:member, login_name: "Commenter") }
  let(:other_member) { FactoryBot.create(:member, login_name: "OtherMember") }
  let(:admin) { FactoryBot.create(:member, :admin, login_name: "AdminUser") }

  # Ensure crop, planting, and garden are created for the harvest
  let(:crop) { FactoryBot.create(:crop) }
  let(:garden) { FactoryBot.create(:garden, owner: harvest_owner) } # Harvest owner also owns garden for simplicity
  let(:planting) { FactoryBot.create(:planting, owner: harvest_owner, crop: crop, garden: garden) }
  let!(:harvest) { FactoryBot.create(:harvest, owner: harvest_owner, planting: planting, description: "My test harvest") }


  def login_as(user)
    visit new_member_session_path
    fill_in "Login Name or Email", with: user.login_name
    fill_in "Password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")
  end

  describe "User comments on a Harvest" do
    before do
      login_as(commenter)
      visit harvest_path(harvest)
    end

    it "allows a user to create a comment" do
      expect(page).to have_content("Comments")
      click_link "Add Comment"

      expect(page).to have_current_path(new_harvest_comment_path(harvest))
      expect(page).to have_content("Add comment to harvest")

      fill_in "comment_body", with: "This harvest looks bountiful!"
      click_button "Post comment"

      expect(page).to have_current_path(harvest_path(harvest))
      expect(page).to have_content("This harvest looks bountiful!")
      expect(page).to have_content(commenter.login_name)
    end
  end

  describe "Editing comments on a Harvest" do
    let!(:comment_to_edit) { FactoryBot.create(:comment, commentable: harvest, author: commenter, body: "Initial harvest comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit harvest_path(harvest)
        find('.comment-body', text: "Initial harvest comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows the author to edit their comment" do
        expect(page).to have_current_path(edit_comment_path(comment_to_edit))
        fill_in "comment_body", with: "Updated harvest comment."
        click_button "Post comment"

        expect(page).to have_current_path(harvest_path(harvest))
        expect(page).to have_content("Updated harvest comment.")
        expect(page).not_to have_content("Initial harvest comment")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit harvest_path(harvest)
        find('.comment-body', text: "Initial harvest comment").ancestor('.comment').find_button('Actions').click
        click_link "Edit"
      end

      it "allows admin to edit any comment" do
        fill_in "comment_body", with: "Admin edited this harvest comment."
        click_button "Post comment"
        expect(page).to have_content("Admin edited this harvest comment.")
      end
    end

    context "as unauthorized user" do
      before do
        login_as(other_member)
        visit harvest_path(harvest)
      end

      it "does not show edit link for other's comment" do
        comment_element = find('.comment-body', text: "Initial harvest comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Edit")
        expect(comment_element).not_to have_button("Actions")
      end
    end
  end

  describe "Deleting comments on a Harvest" do
    let!(:comment_to_delete) { FactoryBot.create(:comment, commentable: harvest, author: commenter, body: "Delete this harvest comment") }

    context "as comment author" do
      before do
        login_as(commenter)
        visit harvest_path(harvest)
        find('.comment-body', text: "Delete this harvest comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the author to delete their comment" do
        expect(page).not_to have_content("Delete this harvest comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as harvest owner" do
      before do
        login_as(harvest_owner)
        visit harvest_path(harvest)
        find('.comment-body', text: "Delete this harvest comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows the harvest owner to delete any comment on their harvest" do
        expect(page).not_to have_content("Delete this harvest comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as admin" do
      before do
        login_as(admin)
        visit harvest_path(harvest)
        find('.comment-body', text: "Delete this harvest comment").ancestor('.comment').find_button('Actions').click
        accept_alert { click_link "Delete" }
      end

      it "allows admin to delete any comment" do
        expect(page).not_to have_content("Delete this harvest comment")
        expect(page).to have_content("Comment was successfully destroyed.")
      end
    end

    context "as unauthorized user" do
      let!(:another_comment) { FactoryBot.create(:comment, commentable: harvest, author: harvest_owner, body: "Harvest owner's comment") }
      before do
        login_as(other_member)
        visit harvest_path(harvest)
      end

      it "does not show delete link for other's comment" do
        comment_element = find('.comment-body', text: "Harvest owner's comment").ancestor('.comment')
        expect(comment_element).not_to have_link("Delete")
        
        comment_element_2 = find('.comment-body', text: "Delete this harvest comment").ancestor('.comment')
        expect(comment_element_2).not_to have_link("Delete")
      end
    end
  end
end
