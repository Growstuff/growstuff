
require 'rails_helper'

describe SeedsController do
  let(:member) { create(:member) }

  describe "GET index with non-existent member" do
    it "returns 404" do
      get :index, params: { member_slug: 'non-existent' }
      expect(response.status).to eq(404)
    end
  end

  describe "GET new with non-existent member" do
    before { sign_in member }
    it "returns 404" do
      get :new, params: { member_slug: 'non-existent' }
      expect(response.status).to eq(404)
    end
  end

  describe "GET index with non-existent crop" do
    it "returns 404" do
      get :index, params: { crop_slug: 'non-existent' }
      expect(response.status).to eq(404)
    end
  end

  describe "GET index with non-existent planting" do
    it "returns 404" do
      get :index, params: { planting_id: 'non-existent' }
      expect(response.status).to eq(404)
    end
  end

  describe "GET new with non-existent planting_slug" do
    before { sign_in member }
    it "returns 404" do
      get :new, params: { planting_slug: 'non-existent' }
      expect(response.status).to eq(404)
    end
  end
end
