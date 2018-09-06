require 'rails_helper'

feature 'Post a post' do
  let(:member) { create :member }

  background do
    login_as member
    visit new_post_path
  end

  scenario "creating a post" do
    fill_in "post_subject", with: "Testing"
    fill_in "post_body", with: "This is a sample test"
    click_button "Post"
    expect(page).to have_content "Post was successfully created"
    expect(page).to have_content "Posted by"
  end

  context "editing a post" do
    let(:existing_post) { create :post, author: member }

    background do
      visit edit_post_path(existing_post)
    end

    scenario "saving edit" do
      fill_in "post_subject", with: "Testing Edit"
      click_button "Post"
      expect(page).to have_content "Post was successfully updated"
      expect(page).to have_content "edited at"
    end
  end
end
