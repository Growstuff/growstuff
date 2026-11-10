# frozen_string_literal: true

require 'rails_helper'

describe "Harvests" do
  let(:member) { create(:member) }
  let(:crop) { create(:crop, name: "Super Tomato") }
  let(:planting) { create(:planting, crop: crop, owner: member, garden: member.gardens.first) }

  describe "GET /harvests" do
    it "works!" do
      get harvests_path
      expect(response).to have_http_status :ok
    end
  end

  describe "GET /plantings/:planting_slug/harvests/new" do
    before { sign_in member }

    describe "prefills planting crop information" do
      before { get new_planting_harvest_path(planting_slug: planting.slug) }

      it { expect(response).to have_http_status :ok }
      it { expect(response.body).to include(crop.name) }
      it { expect(response.body).to include(planting.garden.name) }
    end
  end
end
