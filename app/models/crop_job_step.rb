# frozen_string_literal: true

# One job in a template. When it falls is an offset from an anchor event in the
# planting: "2 weeks after planting out", "1 month before first harvest". It can
# point to a page, its external_uri, that says more about how to do it.
class CropJobStep < ApplicationRecord
  belongs_to :crop_job_template
  has_many :jobs, dependent: :nullify

  enum :offset_unit, { days: 'days', weeks: 'weeks', months: 'months' }, prefix: true, validate: true
  enum :direction, { after: 'after', before: 'before' }, prefix: true, validate: true
  enum :anchor, { sowing: 'sowing', planting_out: 'planting_out', first_harvest: 'first_harvest' }, prefix: true, validate: true
  enum :repeat, { once: 'once', weekly: 'weekly', fortnightly: 'fortnightly', monthly: 'monthly' }, prefix: true, validate: true

  validates :name, presence: true
  validates :offset_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :external_uri, format: { with: %r{\Ahttps?://}, message: :url_format }, allow_blank: true

  # The offset as a duration, negative for a step before its anchor.
  def offset
    duration = offset_amount.public_send(offset_unit)
    direction_before? ? -duration : duration
  end
end
