# frozen_string_literal: true

class ProblemPost < ApplicationRecord
  belongs_to :problem
  belongs_to :post
end
