class Photographing < ActiveRecord::Base
  belongs_to :photo
  belongs_to :photographable, polymorphic: true

  def self.item(item_id, item_type)
    find_by!(photographable_id: item_id, photographable_type: item_type).photographable
  end

  def item
    find_by!(photographable_id: photographable_id, photographable_type: photographable_type).photographable
  end
end
