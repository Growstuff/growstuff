class AddCropToPhotographings < ActiveRecord::Migration[5.2]
  def change
    add_column(:photographings, :crop_id, :integer)
    add_foreign_key(:photographings, :crops)

    Photographing.where(crop_id: nil).each do |p|
      p.set_crop && p.save!
    end
  end
end
