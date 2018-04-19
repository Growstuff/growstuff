module Predictable
  extend ActiveSupport::Concern

  included do
    ## Triggers
    before_save :calculate_lifespan

    def calculate_lifespan
      self.lifespan = (planted_at.present? && finished_at.present? ? finished_at - planted_at : nil)
    end

    # dates
    def first_harvest_date
      harvests_with_dates.minimum(:harvested_at)
    end

    def last_harvest_date
      harvests_with_dates.maximum(:harvested_at)
    end

    def finish_predicted_at
      planted_at + crop.median_lifespan.days if crop.median_lifespan.present? && planted_at.present?
    end

    def first_harvest_predicted_at
      return unless crop.median_days_to_first_harvest.present? && planted_at.present?
      planted_at + crop.median_days_to_first_harvest.days
    end

    def last_harvest_predicted_at
      return unless crop.median_days_to_last_harvest.present? && planted_at.present?
      planted_at + crop.median_days_to_last_harvest.days
    end

    # days
    def age_in_days
      (Time.zone.today - planted_at).to_i if planted_at.present?
    end

    def expected_lifespan
      if planted_at.present? && finished_at.present?
        return (finished_at - planted_at).to_i
      end
      crop.median_lifespan
    end

    def days_since_planted
      (Time.zone.today - planted_at).to_i if planted_at.present?
    end

    # progress
    def percentage_grown
      return 100 if finished
      return if planted_at.blank? || expected_lifespan.blank?
      p = (days_since_planted / expected_lifespan.to_f) * 100
      return p if p <= 100
      100
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

    # states
    def finish_is_predicatable?
      crop.annual? && planted_at.present? && finish_predicted_at.present?
    end

    def zombie?
      crop.annual? && !finished &&
        planted_at.present? &&
        finish_predicted_at.present? &&
        (finish_predicted_at + 60.days) < Time.zone.today
    end

    def should_be_finished?
      crop.annual? && !finished &&
        planted_at.present? &&
        finish_predicted_at.present? &&
        finish_predicted_at < Time.zone.today
    end

    def harvest_time?
      return false if crop.perennial || finished

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
        first_harvest_predicted_at.present? &&
        first_harvest_predicted_at > Time.zone.today
    end
  end
end
