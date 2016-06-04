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

describe RegistrationsController do

  before :each do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    controller.stub(:devise_mapping).and_return(Devise.mappings[:member])
  end

  describe "GET edit" do
    it "assigns the requested member as @member" do
      get :edit
      assigns(:member).should eq(@member)
    end

    it "picks up the twitter auth" do
      @auth = FactoryGirl.create(:authentication, member: @member)
      get :edit
      assigns(:twitter_auth).should eq @auth
    end

    it "picks up the flickr auth" do
      @auth = FactoryGirl.create(:flickr_authentication, member: @member)
      get :edit
      assigns(:flickr_auth).should eq @auth
    end
  end

end
