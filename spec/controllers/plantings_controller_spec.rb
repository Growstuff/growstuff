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

describe PlantingsController do

  login_member

  def valid_attributes
    {
      garden_id: FactoryGirl.create(:garden, owner: subject.current_member).id,
      crop_id: FactoryGirl.create(:crop).id
    }
  end

  describe "GET index" do
    before do
      @member1 = FactoryGirl.create(:member)
      @member2 = FactoryGirl.create(:member)
      @tomato = FactoryGirl.create(:tomato)
      @maize = FactoryGirl.create(:maize)      
      @planting1 = FactoryGirl.create(:planting, crop: @tomato, owner: @member1)
      @planting2 = FactoryGirl.create(:planting, crop: @maize, owner: @member2)
    end
    
    it "assigns all plantings as @plantings" do
      get :index, {}
      assigns(:plantings).should =~ [@planting1, @planting2]
    end

    it "picks up owner from params and shows owner's plantings only" do
      get :index, {owner: @member1.slug}
      assigns(:owner).should eq @member1
      assigns(:plantings).should eq [@planting1]
    end

    it "picks up crop from params and shows the plantings for the crop only" do
      get :index, {crop: @maize.name}
      assigns(:crop).should eq @maize
      assigns(:plantings).should eq [@planting2]    
    end
  end

  describe "GET new" do

    it "picks up crop from params" do
      crop = FactoryGirl.create(:crop)
      get :new, {crop_id: crop.id}
      assigns(:crop).should eq(crop)
    end

    it "doesn't die if no crop specified" do
      get :new, {}
      assigns(:crop).should be_a_new(Crop)
    end

    it "picks up garden from params" do
      member = FactoryGirl.create(:member)
      garden = FactoryGirl.create(:garden, owner: member)
      get :new, {garden_id: garden.id}
      assigns(:garden).should eq(garden)
    end

    it "doesn't die if no garden specified" do
      get :new, {}
      assigns(:garden).should be_a_new(Garden)
    end

    it "sets the date of the planting to today" do
      get :new, {}
      assigns(:planting).planted_at.should == Date.today
    end

    it "sets the owner automatically" do
      post :create, { planting: valid_attributes }
      assigns(:planting).owner.should eq subject.current_member
    end

  end

end
