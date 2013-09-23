class Harvest < ActiveRecord::Base
  extend FriendlyId
  friendly_id :harvest_slug, use: :slugged

  attr_accessible :crop_id, :harvested_at, :description, :owner_id,
    :quantity, :unit, :slug

  belongs_to :crop
  belongs_to :owner, :class_name => 'Member'

  validates :quantity,
    :numericality => { :only_integer => false },
    :allow_nil => true

  UNITS_VALUES = {
    "individual" => "individual",
    "bunches" => "bunch",
    "kg" => "kg",
    "lb" => "lb"
  }
  validates :unit, :inclusion => { :in => UNITS_VALUES.values,
        :message => "%{value} is not a valid unit" },
        :allow_nil => true,
        :allow_blank => true

  after_validation :clear_unit_if_qty_is_blank

  def clear_unit_if_qty_is_blank
    if quantity.blank?
      self.unit = nil
    end
  end

  def harvest_slug
    "#{owner.login_name}-#{crop}".downcase.gsub(' ', '-')
  end

end
