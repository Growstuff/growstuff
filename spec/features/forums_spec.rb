# frozen_string_literal: true

require 'rails_helper'

describe "Forums usage", :js do
  let!(:forum) { create(:forum, name: "General Discussion", description: "Talk about anything") }
  let(:member) { create(:member) }

  describe "browsing forums" do
    it "shows the list of forums" do
      visit forums_path
      expect(page).to have_content("General Discussion")
      expect(page).to have_content("Talk about anything")
    end
  end

  describe "viewing a forum" do
    let!(:post) { create(:post, forum: forum, subject: "Hello World", author: member) }

    it "shows forum details and posts" do
      visit forum_path(forum)
      expect(page).to have_css("h1", text: "General Discussion")
      expect(page).to have_content("Talk about anything")
      expect(page).to have_content("Hello World")
      expect(page).to have_link("Post something")
    end
  end

  describe "starting a new post from a forum" do
    include_context 'signed in member'

    it "pre-fills the forum when creating a new post" do
      visit forum_path(forum)
      click_link "Post something"

      expect(page).to have_current_path(new_post_path(forum_id: forum.id))
      expect(page).to have_content("This post will be posted in the forum #{forum.name}")

      fill_in "post_subject", with: "My New Post"
      fill_in "post_body", with: "Content of my post"
      click_button "Post"

      expect(page).to have_content("Post was successfully created")
      expect(Post.last.forum).to eq(forum)
    end
  end
end
