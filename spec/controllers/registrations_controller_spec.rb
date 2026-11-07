# frozen_string_literal: true

require 'rails_helper'

describe RegistrationsController do
  before do
    @member = create(:member)
    sign_in @member
    controller.stub(:current_user) { @member }
    controller.stub(:devise_mapping).and_return(Devise.mappings[:member])
  end

  describe "GET edit" do
    it "assigns the requested member as @member" do
      get :edit
      assigns(:member).should eq(@member)
    end

    it "picks up the flickr auth" do
      @auth = create(:flickr_authentication, member: @member)
      get :edit
      assigns(:flickr_auth).should eq @auth
    end

    it "picks up mastodon auths" do
      m1 = @member.authentications.create!(provider: 'mastodon', uid: '111', name: '@user1@mastodon.social')
      m2 = @member.authentications.create!(provider: 'mastodon', uid: '222', name: '@user2@mastodon.social')
      get :edit
      expect(assigns(:mastodon_auths)).to match_array([m1, m2])
    end
  end

  describe "POST regenerate_api_token" do
    it "generates or regenerates an API token for the current member" do
      expect do
        post :regenerate_api_token
      end.to change { @member.reload.api_token }.from(nil)
      expect(response).to redirect_to(edit_member_registration_path + '#apps')
    end
  end

  describe "DELETE destroy_api_token" do
    it "destroys the API token for the current member" do
      @member.regenerate_api_token
      expect do
        delete :destroy_api_token
      end.to change { @member.reload.api_token }.to(nil)
      expect(response).to redirect_to(edit_member_registration_path + '#apps')
    end

    it "does not destroy other members' API tokens" do
      other_member = create(:member)
      other_member.regenerate_api_token
      other_token = other_member.api_token

      delete :destroy_api_token

      expect(other_member.reload.api_token).to eq(other_token)
    end
  end
end
