# frozen_string_literal: true

require 'rails_helper'

describe 'Post a post' do
  context 'signed in' do
    include_context 'signed in member'
    before { visit new_post_path }

    it "creating a post" do
      fill_in "post_subject", with: "Testing"
      find(".post-editor-content").send_keys("This is a sample test")
      click_button "Publish post"
      expect(page).to have_content "Post was successfully created"
      expect(page).to have_content "Posted by"
    end

    context "saving a draft" do
      before do
        fill_in "post_subject", with: "Half written"
        find(".post-editor-content").send_keys("Not finished")
        click_button "Save draft"
      end

      it "keeps it as a draft" do
        expect(page).to have_content "Draft was saved"
      end

      it "labels it a draft" do
        expect(page).to have_css ".badge", text: "Draft"
      end

      it "publishes it from the editor" do
        click_link "Actions"
        click_link "Edit"
        click_button "Publish post"
        expect(page).to have_no_css ".badge", text: "Draft"
      end
    end

    context "editing a post" do
      let(:existing_post) { create(:post, author: member) }

      before do
        visit edit_post_path(existing_post)
      end

      it "reaches the edit page from the post's actions menu" do
        visit post_path(existing_post)
        click_link "Actions"
        click_link "Edit"
        expect(page).to have_current_path(edit_post_path(existing_post))
      end

      it "saving edit" do
        fill_in "post_subject", with: "Testing Edit"
        click_button "Save changes"
        expect(page).to have_content "Post was successfully updated"
        expect(page).to have_content "edited at"
      end
    end
  end
end
