class Photographing < ActiveRecord::Base
  belongs_to :photo
  belongs_to :photographable, polymorphic: true
end
