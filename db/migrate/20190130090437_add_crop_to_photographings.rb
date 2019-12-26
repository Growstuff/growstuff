# frozen_string_literal: true

class AddCropToPhotographings < ActiveRecord::Migration[5.2]
  def change
    add_column(:photographings, :crop_id, :integer)
    add_foreign_key(:photographings, :crops)

    Photographing.where(crop_id: nil).each do |p|
      p.set_crop && p.save!
    end
  end
  class Photographing < ApplicationRecord
    belongs_to :photo, inverse_of: :photo_associations
    belongs_to :photographable, polymorphic: true
    belongs_to :crop, optional: true
  end
end
