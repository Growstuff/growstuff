module Finishable
  extend ActiveSupport::Concern

  included do
    scope :finished, -> { where(finished: true) }
    scope :current, -> { where(finished: false) }
  end
end
