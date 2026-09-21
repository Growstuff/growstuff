# frozen_string_literal: true

require 'rails_helper'

describe "Harvest prediction logic" do
  let(:crop) { create(:crop, median_days_to_first_harvest: 20) }
  let(:planting) { create(:planting, crop: crop) }

  describe "#harvest_in_next_week?" do
    it "is true if predicted harvest is in 5 days" do
      planting.planted_at = 15.days.ago
      expect(planting.harvest_in_next_week?).to be true
    end

    it "is true if predicted harvest is today" do
      planting.planted_at = 20.days.ago
      expect(planting.harvest_in_next_week?).to be true
    end

    it "is true if predicted harvest is in 7 days" do
      planting.planted_at = 13.days.ago
      expect(planting.harvest_in_next_week?).to be true
    end

    it "is false if predicted harvest is in 8 days" do
      planting.planted_at = 12.days.ago
      expect(planting.harvest_in_next_week?).to be false
    end

    it "is false if predicted harvest was yesterday" do
      planting.planted_at = 21.days.ago
      expect(planting.harvest_in_next_week?).to be false
    end

    it "is false if there are already harvests" do
      planting.planted_at = 15.days.ago
      create(:harvest, planting: planting, owner: planting.owner, crop: planting.crop, harvested_at: 1.day.ago)
      expect(planting.harvest_in_next_week?).to be false
    end
  end

  describe ".harvest_in_next_week" do
    it "includes plantings with predicted harvest in the next 7 days" do
      planting.update!(planted_at: 15.days.ago)
      expect(Planting.harvest_in_next_week).to include(planting)
    end

    it "includes plantings with predicted harvest today" do
      planting.update!(planted_at: 20.days.ago)
      expect(Planting.harvest_in_next_week).to include(planting)
    end

    it "includes plantings with predicted harvest in exactly 7 days" do
      planting.update!(planted_at: 13.days.ago)
      expect(Planting.harvest_in_next_week).to include(planting)
    end

    it "excludes plantings with predicted harvest in 8 days" do
      planting.update!(planted_at: 12.days.ago)
      expect(Planting.harvest_in_next_week).not_to include(planting)
    end

    it "excludes plantings with predicted harvest in the past" do
      planting.update!(planted_at: 21.days.ago)
      expect(Planting.harvest_in_next_week).not_to include(planting)
    end

    it "excludes plantings that already have harvests" do
      planting.update!(planted_at: 15.days.ago)
      create(:harvest, planting: planting, owner: planting.owner, crop: planting.crop, harvested_at: 1.day.ago)
      expect(Planting.harvest_in_next_week).not_to include(planting)
    end
  end
end
