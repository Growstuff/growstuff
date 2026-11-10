# frozen_string_literal: true

module PredictHarvest
  extend ActiveSupport::Concern

  included do
    # dates
    def first_harvest_date
      return @first_harvest_date if defined?(@first_harvest_date)

      @first_harvest_date = harvests_with_dates.minimum(:harvested_at)
    end

    def last_harvest_date
      return @last_harvest_date if defined?(@last_harvest_date)

      @last_harvest_date = harvests_with_dates.maximum(:harvested_at)
    end

    def first_harvest_predicted_at
      return @first_harvest_predicted_at if defined?(@first_harvest_predicted_at)

      @first_harvest_predicted_at = heat_predicted_first_harvest_at || days_predicted_first_harvest_at
    end

    # Days from planting to when the first harvest is expected, if it is.
    def predicted_days_to_first_harvest
      (first_harvest_predicted_at.to_date - planted_at.to_date).to_i if first_harvest_predicted_at
    end

    def last_harvest_predicted_at
      return @last_harvest_predicted_at if defined?(@last_harvest_predicted_at)

      @last_harvest_predicted_at = if crop.median_days_to_last_harvest.present? && planted_at.present?
                                     planted_at + crop.median_days_to_last_harvest.days
                                   end
    end

    # actions
    def update_harvest_days!
      days_to_first_harvest = nil
      days_to_last_harvest = nil
      if planted_at.present? && harvests_with_dates.size.positive?
        days_to_first_harvest = (first_harvest_date - planted_at).to_i
        days_to_last_harvest = (last_harvest_date - planted_at).to_i if finished?
      end
      update(days_to_first_harvest:, days_to_last_harvest:)
    end

    # status
    def harvest_time?
      return false if crop.perennial || finished || failed

      # We have harvests but haven't finished
      harvests.size.positive? ||

        # or, we don't have harvests, but we predict we should by now
        (first_harvest_predicted_at.present? &&
          harvests.empty? &&
          first_harvest_predicted_at < Time.zone.today)
    end

    def before_harvest_time?
      first_harvest_predicted_at.present? &&
        harvests.empty? &&
        first_harvest_predicted_at > Time.zone.today
    end

    def harvest_in_next_week?
      first_harvest_predicted_at.present? &&
        harvests.empty? &&
        first_harvest_predicted_at >= Time.zone.today &&
        first_harvest_predicted_at <= Time.zone.today + 7.days
    end

    def harvest_months
      Rails.cache.fetch("#{cache_key_with_version}/harvest_months", expires_in: 5.minutes) do
        neighbours_for_harvest_predictions.where.not(harvested_at: nil)
          .group("extract(MONTH from harvested_at)::int")
          .count
      end
    end

    def neighbours_for_harvest_predictions
      @neighbours_for_harvest_predictions ||= begin
        # use this planting's harvest if any
        if harvests.size.positive?
          harvests
        # otherwise use nearby plantings
        elsif location
          Harvest.where(planting: nearby_same_crop.has_harvests)
              .where.not(planting_id: nil)
        else
          Harvest.none
        end
      end
    end

    private

    def harvests_with_dates
      harvests.where.not(harvested_at: nil)
    end

    # The crop's median days to a first harvest after planting, when it has one.
    def days_predicted_first_harvest_at
      planted_at + crop.median_days_to_first_harvest.days if crop.median_days_to_first_harvest.present? && planted_at.present?
    end

    # Whether a first harvest on this day comes after the planting is expected to have finished,
    # going by the crop's median lifespan. Then the heat figures don't fit how this crop is
    # usually grown here, and the median days are the better guide.
    def outlives_median_lifespan?(date)
      date.present? && finish_predicted_at.present? && date.to_date > finish_predicted_at.to_date
    end

    # When the heat this crop needs for a first harvest has been felt in the garden's weather, so far
    # and as expected, or nil when we don't know the heat it needs or have no weather for the garden.
    def heat_predicted_first_harvest_at
      heat = crop.ecocrop_heat_data
      return unless heat && planted_at.present? && weather_located?

      predicted = Rails.cache.fetch("#{cache_key_with_version}/heat_predicted_first_harvest_at", expires_in: 8.hours) do
        degree_days = GrowingDegreeDays.new(base: heat.tmin)
        observed = weather_cell_readings.select(*WeatherReading::CHARTED).between(planted_at, Time.zone.today).order(:date).to_a
        degree_days.date_reaching(heat.first_harvest_degree_days, observed) ||
          degree_days.date_reaching(heat.first_harvest_degree_days,
                                    observed + expected_weather_readings(after: observed.last&.date, through: planted_at + heat.gmax))
      end
      predicted unless outlives_median_lifespan?(predicted)
    end
  end
end
