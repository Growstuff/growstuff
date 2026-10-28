# frozen_string_literal: true

class SeedResource < ApplicationResource
  self.model = Seed

  attribute :description, :string
  attribute :quantity, :integer
  attribute :plant_before, :date
  attribute :tradable_to, :string
  attribute :days_until_maturity_min, :integer
  attribute :days_until_maturity_max, :integer
  attribute :organic, :string
  attribute :gmo, :string
  attribute :heirloom, :string

  # What reading the photos of the packet found, written by the OCR script, which an admin runs. Not shown: it is
  # not on any page yet. Writing it is not a member editing their own seed, so it is not theirs to do.
  attribute :packet_text, :string, readable: false
  before_save do |record|
    context.authorize!(:manage, record) if written?(record) && record.packet_text_changed?
  end

  attribute :crop_id, :integer, readable: false

  belongs_to :crop
  owned
end
