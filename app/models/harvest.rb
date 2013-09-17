class Harvest < ActiveRecord::Base
  attr_accessible :crop_id, :harvested_at, :description, :owner_id, :quantity, :unit

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member'

  validates :quantity,
    :numericality => { :only_integer => false },
    :allow_nil => true

  UNITS_VALUES = %w(individual bunches kg lb)
  validates :unit, :inclusion => { :in => UNITS_VALUES,
        :message => "%{value} is not a valid unit" },
        :allow_nil => true,
        :allow_blank => true

  after_validation :clear_unit_if_qty_is_blank

  def clear_unit_if_qty_is_blank
    if quantity.blank?
      self.unit = nil
    end
  end
end
