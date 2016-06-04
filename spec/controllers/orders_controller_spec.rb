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

describe OrdersController do

  login_member(:admin_member)

  def valid_attributes
    { "member_id" => 1 }
  end

  def valid_session
    {}
  end

  describe "GET checkout" do
    it 'sets the referral_code' do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(member_id: member.id)
      get :checkout, {id: order.to_param, referral_code: 'FOOBAR'}
      order.reload
      order.referral_code.should eq 'FOOBAR'
    end

    it "redirects to Paypal" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(member_id: member.id)
      get :checkout, {id: order.to_param}
      response.status.should eq 302
      response.redirect_url.should match /paypal\.com/
    end
  end

  describe "GET complete" do
    it "assigns the requested order as @order" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(member_id: member.id)
      get :complete, {id: order.to_param}
      assigns(:order).should eq(order)
    end
  end

  describe "DELETE destroy" do
    it "redirects to the shop" do
      member = FactoryGirl.create(:member)
      sign_in member
      order = Order.create!(member_id: member.id)
      delete :destroy, {id: order.id}
      response.should redirect_to(shop_url)
    end
  end

end
