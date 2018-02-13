module Finishable
  extend ActiveSupport::Concern

  included do
    scope :finished, -> { where(finished: true) }
    scope :current, -> { where.not(finished: true) }
  end
end
