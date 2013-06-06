require 'spec_helper'

describe AccountTypesController do

  login_member(:admin_member)

  def valid_attributes
    { "name" => "MyString" }
  end

  describe "GET index" do
    it "assigns all account_types as @account_types" do
      account_type = AccountType.create! valid_attributes
      get :index, {}
      assigns(:account_types).should eq([account_type])
    end
  end

  describe "GET show" do
    it "assigns the requested account_type as @account_type" do
      account_type = AccountType.create! valid_attributes
      get :show, {:id => account_type.to_param}
      assigns(:account_type).should eq(account_type)
    end
  end

  describe "GET new" do
    it "assigns a new account_type as @account_type" do
      get :new, {}
      assigns(:account_type).should be_a_new(AccountType)
    end
  end

  describe "GET edit" do
    it "assigns the requested account_type as @account_type" do
      account_type = AccountType.create! valid_attributes
      get :edit, {:id => account_type.to_param}
      assigns(:account_type).should eq(account_type)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AccountType" do
        expect {
          post :create, {:account_type => valid_attributes}
        }.to change(AccountType, :count).by(1)
      end

      it "assigns a newly created account_type as @account_type" do
        post :create, {:account_type => valid_attributes}
        assigns(:account_type).should be_a(AccountType)
        assigns(:account_type).should be_persisted
      end

      it "redirects to the created account_type" do
        post :create, {:account_type => valid_attributes}
        response.should redirect_to(AccountType.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved account_type as @account_type" do
        # Trigger the behavior that occurs when invalid params are submitted
        AccountType.any_instance.stub(:save).and_return(false)
        post :create, {:account_type => { "name" => "invalid value" }}
        assigns(:account_type).should be_a_new(AccountType)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        AccountType.any_instance.stub(:save).and_return(false)
        post :create, {:account_type => { "name" => "invalid value" }}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested account_type" do
        account_type = AccountType.create! valid_attributes
        # Assuming there are no other account_types in the database, this
        # specifies that the AccountType created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        AccountType.any_instance.should_receive(:update_attributes).with({ "name" => "MyString" })
        put :update, {:id => account_type.to_param, :account_type => { "name" => "MyString" }}
      end

      it "assigns the requested account_type as @account_type" do
        account_type = AccountType.create! valid_attributes
        put :update, {:id => account_type.to_param, :account_type => valid_attributes}
        assigns(:account_type).should eq(account_type)
      end

      it "redirects to the account_type" do
        account_type = AccountType.create! valid_attributes
        put :update, {:id => account_type.to_param, :account_type => valid_attributes}
        response.should redirect_to(account_type)
      end
    end

    describe "with invalid params" do
      it "assigns the account_type as @account_type" do
        account_type = AccountType.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        AccountType.any_instance.stub(:save).and_return(false)
        put :update, {:id => account_type.to_param, :account_type => { "name" => "invalid value" }}
        assigns(:account_type).should eq(account_type)
      end

      it "re-renders the 'edit' template" do
        account_type = AccountType.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        AccountType.any_instance.stub(:save).and_return(false)
        put :update, {:id => account_type.to_param, :account_type => { "name" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested account_type" do
      account_type = AccountType.create! valid_attributes
      expect {
        delete :destroy, {:id => account_type.to_param}
      }.to change(AccountType, :count).by(-1)
    end

    it "redirects to the account_types list" do
      account_type = AccountType.create! valid_attributes
      delete :destroy, {:id => account_type.to_param}
      response.should redirect_to(account_types_url)
    end
  end

end
