# frozen_string_literal: true

class Like < ActiveRecord::Base
  belongs_to :member
  belongs_to :likeable, polymorphic: true
  validates :member, :likeable, presence: true
  validates :member, uniqueness: { scope: :likeable }
end
