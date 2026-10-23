# frozen_string_literal: true

# Something a job can be about: a crop, a planting or some seeds. The job is
# kept when the thing goes, without the link.
module Jobbable
  extend ActiveSupport::Concern

  included do
    has_many :jobs, as: :jobbable, inverse_of: :jobbable, dependent: :nullify
  end
end
