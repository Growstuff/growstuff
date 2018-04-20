module PredictPlanting
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength
    ## Triggers
    before_save :calculate_lifespan

    def calculate_lifespan
      self.lifespan = (planted_at.present? && finished_at.present? ? finished_at - planted_at : nil)
    end

    # dates
    def finish_predicted_at
      planted_at + crop.median_lifespan.days if crop.median_lifespan.present? && planted_at.present?
    end

    # days
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
  end
end
