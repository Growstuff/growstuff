# frozen_string_literal: true

require 'rails_helper'

describe "places/show" do
  subject { rendered }

  let(:member) { create(:london_member) }
  let(:nearby_member) { create(:member) }
  let(:place) { member.location }

  before do
    assign(:place, place)
    allow(view).to receive(:places_map_data).and_return({})
    allow(controller).to receive(:current_user).and_return(member)
    allow(controller).to receive(:current_member).and_return(member)
  end

  context "when nearby members, seeds, and plantings exist" do
    let(:crop) { create(:crop) }
    let(:seed) { create(:seed, crop:, owner: nearby_member) }
    let(:planting) { create(:planting, crop:, owner: nearby_member) }

    before do
      assign(:nearby_members, [nearby_member])
      allow(nearby_member).to receive(:seeds).and_return([seed])
      allow(nearby_member).to receive(:plantings).and_return([planting])
      render
    end

    it "shows the localized page title" do
      expect(view.content_for(:title)).to include(place)
    end

    it "shows the selected place in the search textbox" do
      expect(subject).to have_field("new_place", with: place)
    end

    it "shows the localized nearby members heading" do
      expect(subject).to have_css("#members", text: I18n.t("places.show.nearby_members"))
    end

    it "shows the localized seeds heading" do
      expect(subject).to have_css("#seeds", text: I18n.t("places.show.seeds_available", place:))
    end

    it "shows the localized recent plantings heading" do
      expect(subject).to have_content(I18n.t("places.show.recent_plantings", place:))
    end

    it "shows the names of nearby members" do
      expect(subject).to have_content(nearby_member.login_name)
    end
  end

  context "when no nearby members, seeds, or plantings exist" do
    before do
      assign(:nearby_members, [])
      render
    end

    it "shows the localized empty members message" do
      expect(subject).to have_content(I18n.t("places.show.no_nearby_members"))
    end

    it "shows the localized empty seeds message" do
      expect(subject).to have_content(I18n.t("places.show.no_nearby_seeds"))
    end

    it "shows the localized empty plantings message" do
      expect(subject).to have_content(I18n.t("places.show.no_nearby_plantings"))
    end
  end
end
