# frozen_string_literal: true

class UpgradeCms < ActiveRecord::Migration[5.2]
  def change
    rename_table :comfy_cms_blocks, :comfy_cms_fragments
    rename_column :comfy_cms_fragments, :blockable_id, :record_id
    rename_column :comfy_cms_fragments, :blockable_type, :record_type
    add_column :comfy_cms_fragments, :tag, :string, null: false, default: 'text'
    add_column :comfy_cms_fragments, :datetime, :datetime
    add_column :comfy_cms_fragments, :boolean, :boolean, null: false, default: false
    change_column :comfy_cms_files, :label, :string, null: false, default: ''
    change_column :comfy_cms_files, :file_file_name, :string, null: true
    remove_column :comfy_cms_files, :file_content_type
    remove_column :comfy_cms_files, :file_file_size
    remove_index :comfy_cms_sites, :is_mirrored
    remove_column :comfy_cms_sites, :is_mirrored
    remove_column :comfy_cms_layouts, :is_shared
    remove_column :comfy_cms_pages, :is_shared
    remove_column :comfy_cms_snippets, :is_shared

    limit = 16_777_215
    create_table :comfy_cms_translations, force: true do |t|
      t.string  :locale,    null: false
      t.integer :page_id,   null: false
      t.integer :layout_id
      t.string  :label,           null: false
      t.text    :content_cache,   limit: limit
      t.boolean :is_published,    null: false, default: true
      t.timestamps

      t.index [:page_id]
      t.index [:locale]
      t.index [:is_published]
    end
  end
end
