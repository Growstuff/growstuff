# frozen_string_literal: true

class Like < ApplicationRecord
  belongs_to :member
  belongs_to :likeable, polymorphic: true, counter_cache: true, touch: true
  validates :member, :likeable, presence: true
  validates :member, uniqueness: { scope: :likeable }
end
