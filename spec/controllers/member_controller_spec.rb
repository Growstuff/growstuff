# frozen_string_literal: true

require 'rails_helper'

describe MembersController do
  before do
    @member = FactoryBot.create(:member)
    @twitter_auth = FactoryBot.create(:authentication, member: @member)
    @flickr_auth = FactoryBot.create(:flickr_authentication, member: @member)
  end

  describe "GET index" do
    it "assigns only confirmed members as @members" do
      get :index, params: {}
      expect(assigns(:members)).to eq([@member])
    end
  end

  describe "GET JSON index" do
    it "provides JSON for members" do
      get :index, format: 'json'
      expect(response).to be_successful
    end
  end

  describe "GET show" do
    it "provides JSON for member profile" do
      get :show, params: { slug: @member.to_param }, format: 'json'
      expect(response).to be_successful
    end

    it "assigns @twitter_auth" do
      get :show, params: { slug: @member.to_param }
      expect(assigns(:twitter_auth)).to eq(@twitter_auth)
    end

    it "assigns @flickr_auth" do
      get :show, params: { slug: @member.to_param }
      expect(assigns(:flickr_auth)).to eq(@flickr_auth)
    end

    it "doesn't show completely nonsense members" do
      get :show, params: { slug: 9999 }
      expect(response).to have_http_status(:not_found)
    end

    it "doesn't show unconfirmed members" do
      @member2 = FactoryBot.create(:unconfirmed_member)
      get :show, params: { slug: @member2.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET member's RSS feed" do
    describe "returns an RSS feed" do
      before { get :show, params: { slug: @member.to_param }, format: "rss" }

      it { expect(response).to be_successful }
      it { expect(response).to render_template("members/show") }
      it { expect(response.content_type).to eq("application/rss+xml") }
    end
  end
end
