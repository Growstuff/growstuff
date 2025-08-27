# frozen_string_literal: true

module Finishable
  extend ActiveSupport::Concern

  included do
    scope :finished, -> { where(finished: true) }
    scope :current, -> { where.not(finished: true) }

    def active
      # Plantings can fail. At the moment, activities and seeds cannot.
      if respond_to?(:failed)
        !finished && !failed
      else
        !finished
      end
    end
  end
end
