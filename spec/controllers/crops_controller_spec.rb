require 'rails_helper'

describe CropsController do

  login_member(:crop_wrangling_member)

  def valid_attributes
    {
      :name => "Tomato",
      :en_wikipedia_url => 'http://en.wikipedia.org/wiki/Tomato',
      :approval_status => 'approved'
    }
  end

  describe "GET crop wrangler homepage" do
    it 'fetches the crop wrangler homepage' do
      get :wrangle
      response.should be_success
      response.should render_template("crops/wrangle")
      expect(assigns[:crop_wranglers]).to eq(Role.crop_wranglers)
    end
  end

  describe "GET crop hierarchy " do
    it 'fetches the crop hierarchy page' do
      get :hierarchy
      response.should be_success
      response.should render_template("crops/hierarchy")
    end
  end

  describe "GET crop search" do
    it 'fetches the crop search page' do
      get :search
      response.should be_success
      response.should render_template("crops/search")
    end
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
