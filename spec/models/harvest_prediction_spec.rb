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

  describe "#first_harvest_predicted_at" do
    subject(:predicted_at) { planting.first_harvest_predicted_at }

    let(:today) { Time.zone.today }
    let(:planted_at) { today - 20 }
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, crop:, garden:, owner: garden.owner, planted_at:) }

    def add_weather(dates, **attributes)
      dates.each { |date| create(:weather_reading, date:, temp_max_c: 22.0, temp_min_c: 12.0, **attributes) }
    end

    context "without heat figures for the crop" do
      it "is the median days after planting" do
        expect(predicted_at).to eq planted_at + 20
      end

      it "counts the days from planting" do
        expect(planting.predicted_days_to_first_harvest).to eq 20
      end

      context "when the crop has no median days either" do
        let(:crop) { create(:crop, median_days_to_first_harvest: nil) }

        it "has no day to predict" do
          expect(predicted_at).to be_nil
        end

        it "has no days to count" do
          expect(planting.predicted_days_to_first_harvest).to be_nil
        end
      end
    end

    context "when the crop's growing cycle is recorded as 0 days" do
      before do
        crop.scientific_names.create!(name: "Citrullus lanatus", creator: create(:member))
        create(:ecocrop_data, scientificname: "Citrullus lanatus", tmin: 15, topmn: 20, topmx: 35, gmin: 0, gmax: 0)
        add_weather(planted_at..today)
      end

      it "is the median days after planting, not the day of planting" do
        expect(predicted_at).to eq planted_at + 20
      end
    end

    context "with heat figures for the crop" do
      # Each day gives 7 degree days above the base of 10°C, so the 30 a first harvest needs come on the fifth day.
      before do
        crop.scientific_names.create!(name: "Solanum lycopersicum", creator: create(:member))
        create(:ecocrop_data, scientificname: "Solanum lycopersicum", tmin: 10, topmn: 20, topmx: 30, gmin: 2, gmax: 60)
      end

      context "with the weather already here" do
        before { add_weather(planted_at..(planted_at + 9)) }

        it "is the day the heat adds up" do
          expect(predicted_at).to eq planted_at + 4
        end

        it "counts the days from planting to then" do
          expect(planting.predicted_days_to_first_harvest).to eq 4
        end
      end

      context "when some of the heat is still to come" do
        let(:planted_at) { today - 2 }

        before do
          add_weather(planted_at..(planted_at + 1))
          add_weather(((planted_at + 2)..(planted_at + 6)).map(&:prev_year))
        end

        it "is the day it adds up, counting last year's weather for the days ahead" do
          expect(predicted_at).to eq planted_at + 4
        end
      end

      context "when the median lifespan ends before the heat adds up" do
        let(:crop) { create(:crop, median_days_to_first_harvest: 2, median_lifespan: 3) }

        before { add_weather(planted_at..(planted_at + 9)) }

        it "is the median days after planting" do
          expect(predicted_at).to eq planted_at + 2
        end
      end

      context "when the median lifespan ends after the heat adds up" do
        let(:crop) { create(:crop, median_days_to_first_harvest: 2, median_lifespan: 10) }

        before { add_weather(planted_at..(planted_at + 9)) }

        it "is the day the heat adds up" do
          expect(predicted_at).to eq planted_at + 4
        end
      end

      context "without weather in the garden" do
        it "is the median days after planting" do
          expect(predicted_at).to eq planted_at + 20
        end
      end

      context "when the garden has no location" do
        before { garden.update_columns(latitude: nil, longitude: nil) } # rubocop:disable Rails/SkipsModelValidations

        it "is the median days after planting" do
          expect(predicted_at).to eq planted_at + 20
        end
      end
    end
  end
end
