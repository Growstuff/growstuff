class Seed < ActiveRecord::Base
  attr_accessible :owner_id, :crop_id, :description, :quantity, :plant_before, 
    :tradable, :tradable_to
  belongs_to :crop
  belongs_to :owner, :class_name => 'Member', :foreign_key => 'owner_id'

  TRADABLE_TO_VALUES = %w(locally nationally internationally)
  validates :tradable_to, :inclusion => { :in => TRADABLE_TO_VALUES,
        :message => "You may only trade seed locally, nationally, or internationally" },
        :allow_nil => true,
        :allow_blank => true
end
