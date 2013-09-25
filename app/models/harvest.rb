class Harvest < ActiveRecord::Base
  extend FriendlyId
  friendly_id :harvest_slug, use: :slugged

  attr_accessible :crop_id, :harvested_at, :description, :owner_id,
    :quantity, :unit, :weight_quantity, :weight_unit, :slug

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member'

  validates :quantity,
    :numericality => { :only_integer => false },
    :allow_nil => true

  UNITS_VALUES = {
    "individual" => "individual",
    "bunches" => "bunch"
  }
  validates :unit, :inclusion => { :in => UNITS_VALUES.values,
        :message => "%{value} is not a valid unit" },
        :allow_nil => true,
        :allow_blank => true

  validates :weight_quantity,
    :numericality => { :only_integer => false },
    :allow_nil => true

  WEIGHT_UNITS_VALUES = {
    "kg" => "kg",
    "lb" => "lb"
  }
  validates :weight_unit, :inclusion => { :in => WEIGHT_UNITS_VALUES.values,
        :message => "%{value} is not a valid unit" },
        :allow_nil => true,
        :allow_blank => true

  after_validation :clear_unit_if_qty_is_blank
  after_validation :clear_weight_unit_if_weight_qty_is_blank

  def clear_unit_if_qty_is_blank
    if quantity.blank?
      self.unit = nil
    end
  end

  def clear_weight_unit_if_weight_qty_is_blank
    if weight_quantity.blank?
      self.weight_unit = nil
    end
  end

  def harvest_slug
    "#{owner.login_name}-#{crop}".downcase.gsub(' ', '-')
  end

end
