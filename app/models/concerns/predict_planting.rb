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
      if planted_at.blank?
        nil
      elsif crop.median_lifespan.present?
        planted_at + crop.median_lifespan.days
      elsif crop.parent.present? && crop.parent.median_lifespan.present?
        planted_at + crop.parent.median_lifespan.days
      end
    end

    # days
    def expected_lifespan
      if actual_lifespan.present?
        actual_lifespan
      elsif crop.median_lifespan.present?
        crop.median_lifespan
      elsif crop.parent.present? && crop.parent.median_lifespan.present?
        crop.parent.median_lifespan
      end
    end

    def actual_lifespan
      return unless planted_at.present? && finished_at.present?

      (finished_at - planted_at).to_i
    end

    def days_since_planted
      (Time.zone.today - planted_at).to_i if planted_at.present?
    end

    def percentage_grown
      if finished?
        100
      elsif !planted?
        0
      elsif crop.perennial || finish_predicted_at.nil?
        nil
      else
        calculate_percentage_grown
      end
    end

    # states
    def finish_is_predicatable?
      crop.annual? && planted_at.present? && finish_predicted_at.present?
    end

    # Planting has live more then 90 days past predicted finish
    def super_late?
      late? && (finish_predicted_at + 90.days) < Time.zone.today
    end

    def late?
      crop.annual? && !finished &&
        planted_at.present? &&
        finish_predicted_at.present? &&
        finish_predicted_at <= Time.zone.today
    end

    private

    def calculate_percentage_grown
      percent = (days_since_planted / expected_lifespan.to_f) * 100
      (percent > 100 ? 100 : percent)
    end
  end
end
