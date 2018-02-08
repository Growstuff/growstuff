require 'rails_helper'

describe PostsController do
  login_member

  def valid_attributes
    member = FactoryBot.create(:member)
    { author_id: member.id, subject: "blah", body: "blah blah" }
  end

  describe "GET RSS feed" do
    it "returns an RSS feed" do
      get :index, format: "rss"
      response.should be_success
      response.should render_template("posts/index")
      response.content_type.should eq("application/rss+xml")
    end
  end

  describe "GET RSS feed for individual post" do
    it "returns an RSS feed" do
      post = Post.create! valid_attributes
      get :show, format: "rss", id: post.slug
      response.should be_success
      response.should render_template("posts/show")
      response.content_type.should eq("application/rss+xml")
    end
  end
end
