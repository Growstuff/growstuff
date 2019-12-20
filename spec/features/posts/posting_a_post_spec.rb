# frozen_string_literal: true

require 'rails_helper'

describe 'Post a post' do
  context 'signed in' do
    include_context 'signed in member'
    before { visit new_post_path }

    it "creating a post" do
      fill_in "post_subject", with: "Testing"
      fill_in "post_body", with: "This is a sample test"
      click_button "Post"
      expect(page).to have_content "Post was successfully created"
      expect(page).to have_content "Posted by"
    end

    context "editing a post" do
      let(:existing_post) { create :post, author: member }

      before do
        visit edit_post_path(existing_post)
      end

      it "saving edit" do
        fill_in "post_subject", with: "Testing Edit"
        click_button "Post"
        expect(page).to have_content "Post was successfully updated"
        expect(page).to have_content "edited at"
      end
    end
  end
end
