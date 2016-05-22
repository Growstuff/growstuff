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

describe Admin::OrdersController do

  login_member(:admin_member)

  describe "GET search" do
    it "assigns @orders" do
      order = FactoryGirl.create(:order)
      get :search, {search_by: 'order_id', search_text: order.id}
      assigns(:orders).should eq([order])
    end

    it "sets an error message if nothing found" do
      order = FactoryGirl.create(:order)
      get :search, {search_by: 'order_id', search_text: 'foo'}
      flash[:alert].should match /Couldn't find order with/
    end
  end

end
