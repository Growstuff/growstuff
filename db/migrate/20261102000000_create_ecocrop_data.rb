# frozen_string_literal: true

class CreateEcocropData < ActiveRecord::Migration[8.1]
  def change
    create_table :ecocrop_data do |t|
      t.integer :ecoportcode, index: { unique: true }
      t.string :scientificname, index: true
      t.string :auth
      t.string :famname
      t.string :syno, array: true, default: []
      t.string :comname, array: true, default: []
      t.string :lifo, array: true, default: []
      t.string :habi, array: true, default: []
      t.string :lispa, array: true, default: []
      t.string :phys, array: true, default: []
      t.string :cat, array: true, default: []
      t.string :plat, array: true, default: []
      t.string :prosy, array: true, default: []
      t.integer :topmn
      t.integer :topmx
      t.integer :tmin
      t.integer :tmax
      t.integer :ktmp
      t.integer :ktmpr
      t.integer :ropmn
      t.integer :ropmx
      t.integer :rmin
      t.integer :rmax
      t.integer :gmin
      t.integer :gmax
      t.decimal :phopmn
      t.decimal :phopmx
      t.decimal :phmin
      t.decimal :phmax
      t.decimal :latopmn
      t.decimal :latopmx
      t.decimal :latmn
      t.decimal :latmx
      t.integer :altmx
      t.string :liopmn
      t.string :liopmx
      t.string :limn
      t.string :limx
      t.string :dep
      t.string :depr
      t.string :text, array: true, default: []
      t.string :textr, array: true, default: []
      t.string :fer
      t.string :ferr
      t.string :tox
      t.string :toxr
      t.string :sal
      t.string :salr
      t.string :dra, array: true, default: []
      t.string :drar, array: true, default: []
      t.string :photo, array: true, default: []
      t.string :cliz, array: true, default: []
      t.string :abitol, array: true, default: []
      t.string :abisus, array: true, default: []
      t.string :intri, array: true, default: []

      t.timestamps
    end
  end
end
