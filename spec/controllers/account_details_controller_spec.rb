require 'spec_helper'

describe AccountDetailsController do

  login_member(:admin_member)

  def valid_attributes
    { "paid_until" => Time.now }
  end

  def create_account_detail
    # account details are automatically created when you create a new
    # member; creating them manually will just cause errors as only one is
    # allowed.

    member = FactoryGirl.create(:member)
    return member.account_detail
  end

  describe "GET index" do
    it "assigns all account_details as @account_details" do
      account_detail = create_account_detail
      get :index, {}
      # can't match the whole list because it includes the one for the
      # logged in admin member, sigh
      assigns(:account_details).should include(account_detail)
      assigns(:account_details).count.should eq 2
    end
  end

  describe "GET show" do
    it "assigns the requested account_detail as @account_detail" do
      account_detail = create_account_detail
      get :show, {:id => account_detail.to_param}
      assigns(:account_detail).should eq(account_detail)
    end
  end

  describe "GET edit" do
    it "assigns the requested account_detail as @account_detail" do
      account_detail = create_account_detail
      get :edit, {:id => account_detail.to_param}
      assigns(:account_detail).should eq(account_detail)
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested account_detail" do
        account_detail = create_account_detail
        # Assuming there are no other account_detail in the database, this
        # specifies that the AccountDetail created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        AccountDetail.any_instance.should_receive(:update_attributes).with({ "member_id" => "1" })
        put :update, {:id => account_detail.to_param, :account_detail => { "member_id" => "1" }}
      end

      it "assigns the requested account_detail as @account_detail" do
        account_detail = create_account_detail
        put :update, {:id => account_detail.to_param, :account_detail => valid_attributes}
        assigns(:account_detail).should eq(account_detail)
      end

      it "redirects to the account_detail" do
        account_detail = create_account_detail
        put :update, {:id => account_detail.to_param, :account_detail => valid_attributes}
        response.should redirect_to(account_detail)
      end
    end

    describe "with invalid params" do
      it "assigns the account_detail as @account_detail" do
        account_detail = create_account_detail
        # Trigger the behavior that occurs when invalid params are submitted
        AccountDetail.any_instance.stub(:save).and_return(false)
        put :update, {:id => account_detail.to_param, :account_detail => { "member_id" => "invalid value" }}
        assigns(:account_detail).should eq(account_detail)
      end

      it "re-renders the 'edit' template" do
        account_detail = create_account_detail
        # Trigger the behavior that occurs when invalid params are submitted
        AccountDetail.any_instance.stub(:save).and_return(false)
        put :update, {:id => account_detail.to_param, :account_detail => { "member_id" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

end
