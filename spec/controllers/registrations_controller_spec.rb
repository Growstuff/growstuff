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
      expect(assigns(:member)).to eq(@member)
    end

    it "picks up the flickr auth" do
      @auth = create(:flickr_authentication, member: @member)
      get :edit
      expect(assigns(:flickr_auth)).to eq @auth
    end
  end
end
