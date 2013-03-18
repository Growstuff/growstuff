require 'spec_helper'

describe ForumsController do

  login_member(:admin_member)

  def valid_attributes
    {
      "name" => "MyString",
      "description" => "Something",
      "owner_id" => 1
    }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all forums as @forums" do
      forum = Forum.create! valid_attributes
      get :index, {}
      assigns(:forums).should eq([forum])
    end
  end

  describe "GET show" do
    it "assigns the requested forum as @forum" do
      forum = Forum.create! valid_attributes
      get :show, {:id => forum.to_param}
      assigns(:forum).should eq(forum)
    end
  end

  describe "GET new" do
    it "assigns a new forum as @forum" do
      get :new, {}
      assigns(:forum).should be_a_new(Forum)
    end
  end

  describe "GET edit" do
    it "assigns the requested forum as @forum" do
      forum = Forum.create! valid_attributes
      get :edit, {:id => forum.to_param}
      assigns(:forum).should eq(forum)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Forum" do
        expect {
          post :create, {:forum => valid_attributes}
        }.to change(Forum, :count).by(1)
      end

      it "assigns a newly created forum as @forum" do
        post :create, {:forum => valid_attributes}
        assigns(:forum).should be_a(Forum)
        assigns(:forum).should be_persisted
      end

      it "redirects to the created forum" do
        post :create, {:forum => valid_attributes}
        response.should redirect_to(Forum.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved forum as @forum" do
        # Trigger the behavior that occurs when invalid params are submitted
        Forum.any_instance.stub(:save).and_return(false)
        post :create, {:forum => { "name" => "invalid value" }}
        assigns(:forum).should be_a_new(Forum)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Forum.any_instance.stub(:save).and_return(false)
        post :create, {:forum => { "name" => "invalid value" }}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested forum" do
        forum = Forum.create! valid_attributes
        # Assuming there are no other forums in the database, this
        # specifies that the Forum created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Forum.any_instance.should_receive(:update_attributes).with({ "name" => "MyString" })
        put :update, {:id => forum.to_param, :forum => { "name" => "MyString" }}
      end

      it "assigns the requested forum as @forum" do
        forum = Forum.create! valid_attributes
        put :update, {:id => forum.to_param, :forum => valid_attributes}
        assigns(:forum).should eq(forum)
      end

      it "redirects to the forum" do
        forum = Forum.create! valid_attributes
        put :update, {:id => forum.to_param, :forum => valid_attributes}
        response.should redirect_to(forum)
      end
    end

    describe "with invalid params" do
      it "assigns the forum as @forum" do
        forum = Forum.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Forum.any_instance.stub(:save).and_return(false)
        put :update, {:id => forum.to_param, :forum => { "name" => "invalid value" }}
        assigns(:forum).should eq(forum)
      end

      it "re-renders the 'edit' template" do
        forum = Forum.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Forum.any_instance.stub(:save).and_return(false)
        put :update, {:id => forum.to_param, :forum => { "name" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested forum" do
      forum = Forum.create! valid_attributes
      expect {
        delete :destroy, {:id => forum.to_param}
      }.to change(Forum, :count).by(-1)
    end

    it "redirects to the forums list" do
      forum = Forum.create! valid_attributes
      delete :destroy, {:id => forum.to_param}
      response.should redirect_to(forums_url)
    end
  end

end
