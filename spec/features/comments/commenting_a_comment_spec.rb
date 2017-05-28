require 'rails_helper'

feature 'Commenting on a post' do
  let(:member) { create :member }
  let(:post) { create :post, author: member }

  background do
    login_as member
    visit new_comment_path post_id: post.id
  end

  scenario "creating a comment" do
    fill_in "comment_body", with: "This is a sample test for comment"
    click_button "Post comment"
    expect(page).to have_content "comment was successfully created."
    expect(page).to have_content "Posted by"
  end

  context "editing a comment" do
    let(:existing_comment) { create :comment, post: post, author: member }

    background do
      visit edit_comment_path existing_comment
    end

    scenario "saving edit" do
      fill_in "comment_body", with: "Testing edit for comment"
      click_button "Post comment"
      expect(page).to have_content "comment was successfully updated."
      expect(page).to have_content "edited at"
    end
  end
end
