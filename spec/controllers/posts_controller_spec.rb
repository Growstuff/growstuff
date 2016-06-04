## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe PostsController do

  login_member

  def valid_attributes
    member = FactoryGirl.create(:member)
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
      get :show, { format: "rss", id: post.slug }
      response.should be_success
      response.should render_template("posts/show")
      response.content_type.should eq("application/rss+xml")
    end
  end

end
