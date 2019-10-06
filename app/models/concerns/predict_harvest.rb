module PredictHarvest
  extend ActiveSupport::Concern

  included do
    # rubocop:disable Metrics/BlockLength
    # dates
    def first_harvest_date
      harvests_with_dates.minimum(:harvested_at)
    end

    def last_harvest_date
      harvests_with_dates.maximum(:harvested_at)
    end

    def first_harvest_predicted_at
      return unless crop.median_days_to_first_harvest.present? && planted_at.present?

      planted_at + crop.median_days_to_first_harvest.days
    end

    def last_harvest_predicted_at
      return unless crop.median_days_to_last_harvest.present? && planted_at.present?

      planted_at + crop.median_days_to_last_harvest.days
    end

    # actions
    def update_harvest_days!
      days_to_first_harvest = nil
      days_to_last_harvest = nil

      if planted_at.present? && harvests_with_dates.size.positive?
        days_to_first_harvest = (first_harvest_date - planted_at).to_i
        days_to_last_harvest = (last_harvest_date - planted_at).to_i if finished?
      end
      update(days_to_first_harvest: days_to_first_harvest, days_to_last_harvest: days_to_last_harvest)
    end

    # status
    def harvest_time?
      return false if crop.perennial || finished

      # We have harvests but haven't finished
      harvests.size.positive? ||
        (first_harvest_predicted_at.present? && harvests.empty? && first_harvest_predicted_at < Time.zone.today)
      # or, we don't have harvests, but we predict we should by now
    end

    def before_harvest_time?
      first_harvest_predicted_at.present? && harvests.empty? && first_harvest_predicted_at.present? &&
        first_harvest_predicted_at > Time.zone.today
    end

    private

    def harvests_with_dates
      harvests.where.not(harvested_at: nil)
    end
  end
end
