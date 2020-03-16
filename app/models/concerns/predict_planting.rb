# frozen_string_literal: true

module PredictPlanting
  extend ActiveSupport::Concern

  included do
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

    def age_in_days
      return if planted_at.blank?

      known_last_day ||= finished_at || Time.zone.today
      (known_last_day - planted_at).to_i
    end

    def percentage_grown
      Rails.cache.fetch("#{cache_key_with_version}/percentage_grown", expires_in: 8.hours) do
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
      percent = (age_in_days / expected_lifespan.to_f) * 100
      (percent > 100 ? 100 : percent)
    end
  end
end
