require 'spec_helper'

describe AccountsController do

  login_member(:admin_member)

  def valid_attributes
    { "paid_until" => Time.now }
  end

  def create_account
    # account details are automatically created when you create a new
    # member; creating them manually will just cause errors as only one is
    # allowed.

    member = FactoryGirl.create(:member)
    return member.account
  end

  describe "GET index" do
    it "assigns all accounts as @accounts" do
      account = create_account
      get :index, {}
      # can't match the whole list because it includes the one for the
      # logged in admin member, sigh
      assigns(:accounts).should include(account)
      assigns(:accounts).count.should eq 2
    end
  end

  describe "GET show" do
    it "assigns the requested account as @account" do
      account = create_account
      get :show, {:id => account.to_param}
      assigns(:account).should eq(account)
    end
  end

  describe "GET edit" do
    it "assigns the requested account as @account" do
      account = create_account
      get :edit, {:id => account.to_param}
      assigns(:account).should eq(account)
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested account" do
        account = create_account
        # Assuming there are no other account in the database, this
        # specifies that the Account created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Account.any_instance.should_receive(:update_attributes).with({ "member_id" => "1" })
        put :update, {:id => account.to_param, :account => { "member_id" => "1" }}
      end

      it "assigns the requested account as @account" do
        account = create_account
        put :update, {:id => account.to_param, :account => valid_attributes}
        assigns(:account).should eq(account)
      end

      it "redirects to the account" do
        account = create_account
        put :update, {:id => account.to_param, :account => valid_attributes}
        response.should redirect_to(account)
      end
    end

    describe "with invalid params" do
      it "assigns the account as @account" do
        account = create_account
        # Trigger the behavior that occurs when invalid params are submitted
        Account.any_instance.stub(:save).and_return(false)
        put :update, {:id => account.to_param, :account => { "member_id" => "invalid value" }}
        assigns(:account).should eq(account)
      end

      it "re-renders the 'edit' template" do
        account = create_account
        # Trigger the behavior that occurs when invalid params are submitted
        Account.any_instance.stub(:save).and_return(false)
        put :update, {:id => account.to_param, :account => { "member_id" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

end
