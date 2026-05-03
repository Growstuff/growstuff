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

      @first_harvest_predicted_at = if crop.median_days_to_first_harvest.present? && planted_at.present?
                                      planted_at + crop.median_days_to_first_harvest.days
                                    end
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
  end
end
