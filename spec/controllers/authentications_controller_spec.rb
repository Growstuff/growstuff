require 'spec_helper'

describe AuthenticationsController do

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_member) { @member }
    @auth = FactoryGirl.create(:authentication, :member => @member)
    request.env['omniauth.auth'] = {
      'provider' => 'foo',
      'uid' => 'bar',
      'info' => { 'nickname' => 'blah' },
      'credentials' => { 'token' => 'blah', 'secret' => 'blah' }
    }
  end

  describe "GET index" do
    it "assigns all authentications as @authentications" do
      get :index, {}
      assigns(:authentications).should eq([@auth])
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Authentication" do
        expect {
          post :create, {:authentication => @auth}
        }.to change(Authentication, :count).by(1)
      end

      it "assigns a newly created authentication as @authentication" do
        post :create, {:authentication => @auth}
        assigns(:authentication).should be_a(Authentication)
        assigns(:authentication).should be_persisted
      end

      it "redirects to the settings page" do
        post :create, {:authentication => @auth }
        response.should redirect_to(edit_member_registration_path)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved authentication as @authentication" do
        # Trigger the behavior that occurs when invalid params are submitted
        Authentication.any_instance.stub(:save).and_return(false)
        post :create, {:authentication => { "member_id" => "invalid value" }}
        assigns(:authentication).should be_a_new(Authentication)
      end

      it "redirects to settings page" do
        # Trigger the behavior that occurs when invalid params are submitted
        Authentication.any_instance.stub(:save).and_return(false)
        post :create, {:authentication => { "member_id" => "invalid value" }}
        response.should redirect_to(edit_member_registration_path)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested authentication" do
      authentication = @auth
      expect {
        delete :destroy, {:id => authentication.to_param}
      }.to change(Authentication, :count).by(-1)
    end

    it "redirects to the settings page" do
      authentication = @auth
      delete :destroy, {:id => authentication.to_param}
      response.should redirect_to(edit_member_registration_path)
    end
  end

end
