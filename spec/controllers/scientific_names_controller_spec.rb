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

describe ScientificNamesController do

  login_member(:crop_wrangling_member)

  before(:each) do
    @crop = FactoryGirl.create(:tomato)
  end

  def valid_attributes
    { scientific_name: 'Solanum lycopersicum', crop_id: @crop.id }
  end

  describe "GET new" do
    it "assigns crop if specified" do
      get :new, { crop_id: 1 }
      assigns(:crop).should be_an_instance_of Crop
    end

  end
end
