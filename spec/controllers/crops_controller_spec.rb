require 'spec_helper'

describe CropsController do

  login_member(:crop_wrangling_member)

  def valid_attributes
    {
      :system_name => "Tomato",
      :en_wikipedia_url => 'http://en.wikipedia.org/wiki/Tomato'
    }
  end

  describe "GET RSS feed" do
    it "returns an RSS feed" do
      get :index, :format => "rss"
      response.should be_success
      response.should render_template("crops/index")
      response.content_type.should eq("application/rss+xml")
    end
  end

end
