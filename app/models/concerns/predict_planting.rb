# frozen_string_literal: true

module PredictPlanting
  extend ActiveSupport::Concern

  included do
    ## Triggers
    before_save :calculate_lifespan

    def calculate_lifespan
      self.lifespan = (planted_at.present? && finished_at.present? && !failed? ? finished_at - planted_at : nil)
    end

    # dates

    # When the planting is expected to finish: the day its crop's plantings usually finish, but never before the planting
    # has had its harvests. The first comes from the heat the garden's weather gives it, so a crop that most people stop
    # recording early still shows as growing until it has had the heat it needs. Nil when the crop has no usual finish.
    # Every progress bar, badge and date for a planting's finish reads this one date.
    def finish_predicted_at
      return @finish_predicted_at if defined?(@finish_predicted_at)

      @finish_predicted_at = if planted_at.blank? || failed? || median_finish_at.nil?
                               nil
                             else
                               [median_finish_at, harvests_finish_at].compact.max
                             end
    end

    # days
    def expected_lifespan
      return @expected_lifespan if defined?(@expected_lifespan)

      @expected_lifespan = if actual_lifespan.present?
                             actual_lifespan
                           elsif finish_predicted_at.present?
                             (finish_predicted_at - planted_at).to_i
                           else
                             median_lifespan_days
                           end
    end

    def actual_lifespan
      return @actual_lifespan if defined?(@actual_lifespan)

      @actual_lifespan = if planted_at.present? && finished_at.present? && !failed?
                           (finished_at - planted_at).to_i
                         end
    end

    def age_in_days
      return @age_in_days if defined?(@age_in_days)

      @age_in_days = if planted_at.blank? || failed?
                       nil
                     else
                       known_last_day = finished_at || Time.zone.today
                       known_last_day = Time.zone.today if known_last_day > Time.zone.today

                       (known_last_day - planted_at).to_i
                     end
    end

    def percentage_grown
      Rails.cache.fetch("#{cache_key_with_version}/percentage_grown", expires_in: 8.hours) do
        if finished?
          100
        elsif !planted? || failed?
          0
        elsif crop.perennial || (finish_predicted_at.nil? && finished_at.nil?) # This covers future dated finished_at that hasn't occurrred yet.
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

    # How the planting is getting on, for colouring its progress bar.
    def progress_state
      if finished?
        :finished
      elsif super_late?
        :super_late
      elsif late?
        :late
      elsif harvest_time?
        :harvesting
      else
        :growing
      end
    end

    # Planting has live more then 90 days past predicted finish
    def super_late?
      late? && (finish_predicted_at + 90.days) < Time.zone.today
    end

    def late?
      crop.annual? && !finished && !failed &&
        planted_at.present? &&
        finish_predicted_at.present? &&
        finish_predicted_at <= Time.zone.today
    end

    # Deactivate any plantings over time_limit that are super late in small batches.
    def self.archive!(time_limit: 3.years.ago, limit: 1000)
      active_plantings = Planting.annual.active.where("planted_at < ?", time_limit).order(planted_at: :asc).limit(limit)
      active_plantings.each do |planting|
        if planting.finish_is_predicatable? && planting.super_late?
          planting.finished = true
          planting.save
        end
      end
    end

    private

    # The crop's median lifespan, or its parent's when the crop has none.
    def median_lifespan_days
      crop.median_lifespan.presence || crop.parent&.median_lifespan.presence
    end

    def median_finish_at
      planted_at + median_lifespan_days.days if median_lifespan_days.present?
    end

    # The day the harvests we predict are done: the last of the heat-predicted first harvest and the median last
    # harvest. Only for an annual, which is grown to a finish.
    def harvests_finish_at
      return unless crop.annual?

      [heat_predicted_first_harvest_at, last_harvest_predicted_at].compact.max
    end

    def calculate_percentage_grown
      return 0 if age_in_days.to_i < 0

      percent = (age_in_days.to_f / expected_lifespan.to_f) * 100
      (percent > 100 ? 100 : percent)
    end
  end
end
