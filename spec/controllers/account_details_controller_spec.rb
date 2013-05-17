require 'spec_helper'

describe AccountDetailsController do

  def valid_attributes
    { "member_id" => "1" }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all account_details as @account_details" do
      account_detail = AccountDetail.create! valid_attributes
      get :index, {}, valid_session
      assigns(:account_details).should eq([account_detail])
    end
  end

  describe "GET show" do
    it "assigns the requested account_detail as @account_detail" do
      account_detail = AccountDetail.create! valid_attributes
      get :show, {:id => account_detail.to_param}, valid_session
      assigns(:account_detail).should eq(account_detail)
    end
  end

  describe "GET new" do
    it "assigns a new account_detail as @account_detail" do
      get :new, {}, valid_session
      assigns(:account_detail).should be_a_new(AccountDetail)
    end
  end

  describe "GET edit" do
    it "assigns the requested account_detail as @account_detail" do
      account_detail = AccountDetail.create! valid_attributes
      get :edit, {:id => account_detail.to_param}, valid_session
      assigns(:account_detail).should eq(account_detail)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AccountDetail" do
        expect {
          post :create, {:account_detail => valid_attributes}, valid_session
        }.to change(AccountDetail, :count).by(1)
      end

      it "assigns a newly created account_detail as @account_detail" do
        post :create, {:account_detail => valid_attributes}, valid_session
        assigns(:account_detail).should be_a(AccountDetail)
        assigns(:account_detail).should be_persisted
      end

      it "redirects to the created account_detail" do
        post :create, {:account_detail => valid_attributes}, valid_session
        response.should redirect_to(AccountDetail.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved account_detail as @account_detail" do
        # Trigger the behavior that occurs when invalid params are submitted
        AccountDetail.any_instance.stub(:save).and_return(false)
        post :create, {:account_detail => { "member_id" => "invalid value" }}, valid_session
        assigns(:account_detail).should be_a_new(AccountDetail)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        AccountDetail.any_instance.stub(:save).and_return(false)
        post :create, {:account_detail => { "member_id" => "invalid value" }}, valid_session
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested account_detail" do
        account_detail = AccountDetail.create! valid_attributes
        # Assuming there are no other account_details in the database, this
        # specifies that the AccountDetail created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        AccountDetail.any_instance.should_receive(:update_attributes).with({ "member_id" => "1" })
        put :update, {:id => account_detail.to_param, :account_detail => { "member_id" => "1" }}, valid_session
      end

      it "assigns the requested account_detail as @account_detail" do
        account_detail = AccountDetail.create! valid_attributes
        put :update, {:id => account_detail.to_param, :account_detail => valid_attributes}, valid_session
        assigns(:account_detail).should eq(account_detail)
      end

      it "redirects to the account_detail" do
        account_detail = AccountDetail.create! valid_attributes
        put :update, {:id => account_detail.to_param, :account_detail => valid_attributes}, valid_session
        response.should redirect_to(account_detail)
      end
    end

    describe "with invalid params" do
      it "assigns the account_detail as @account_detail" do
        account_detail = AccountDetail.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        AccountDetail.any_instance.stub(:save).and_return(false)
        put :update, {:id => account_detail.to_param, :account_detail => { "member_id" => "invalid value" }}, valid_session
        assigns(:account_detail).should eq(account_detail)
      end

      it "re-renders the 'edit' template" do
        account_detail = AccountDetail.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        AccountDetail.any_instance.stub(:save).and_return(false)
        put :update, {:id => account_detail.to_param, :account_detail => { "member_id" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested account_detail" do
      account_detail = AccountDetail.create! valid_attributes
      expect {
        delete :destroy, {:id => account_detail.to_param}, valid_session
      }.to change(AccountDetail, :count).by(-1)
    end

    it "redirects to the account_details list" do
      account_detail = AccountDetail.create! valid_attributes
      delete :destroy, {:id => account_detail.to_param}, valid_session
      response.should redirect_to(account_details_url)
    end
  end

end
