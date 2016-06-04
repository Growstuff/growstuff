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

describe CropsController do

  login_member(:crop_wrangling_member)

  def valid_attributes
    {
      name: "Tomato",
      en_wikipedia_url: 'http://en.wikipedia.org/wiki/Tomato',
      approval_status: 'approved'
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
      get :index, format: "rss"
      response.should be_success
      response.should render_template("crops/index")
      response.content_type.should eq("application/rss+xml")
    end
  end

end
