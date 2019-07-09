# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_07_08_104319) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alternate_names", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "crop_id", null: false
    t.integer "creator_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authentications", id: :serial, force: :cascade do |t|
    t.integer "member_id", null: false
    t.string "provider", null: false
    t.string "uid"
    t.string "token"
    t.string "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.index ["member_id"], name: "index_authentications_on_member_id"
  end

  create_table "comfy_cms_blocks", id: :serial, force: :cascade do |t|
    t.string "identifier", null: false
    t.text "content"
    t.string "blockable_type"
    t.integer "blockable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["blockable_id", "blockable_type"], name: "index_comfy_cms_blocks_on_blockable_id_and_blockable_type"
    t.index ["identifier"], name: "index_comfy_cms_blocks_on_identifier"
  end

  create_table "comfy_cms_categories", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "categorized_type", null: false
    t.index ["site_id", "categorized_type", "label"], name: "index_cms_categories_on_site_id_and_cat_type_and_label", unique: true
  end

  create_table "comfy_cms_categorizations", id: :serial, force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "categorized_type", null: false
    t.integer "categorized_id", null: false
    t.index ["category_id", "categorized_type", "categorized_id"], name: "index_cms_categorizations_on_cat_id_and_catd_type_and_catd_id", unique: true
  end

  create_table "comfy_cms_files", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "block_id"
    t.string "label", null: false
    t.string "file_file_name", null: false
    t.string "file_content_type", null: false
    t.integer "file_file_size", null: false
    t.string "description", limit: 2048
    t.integer "position", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["site_id", "block_id"], name: "index_comfy_cms_files_on_site_id_and_block_id"
    t.index ["site_id", "file_file_name"], name: "index_comfy_cms_files_on_site_id_and_file_file_name"
    t.index ["site_id", "label"], name: "index_comfy_cms_files_on_site_id_and_label"
    t.index ["site_id", "position"], name: "index_comfy_cms_files_on_site_id_and_position"
  end

  create_table "comfy_cms_layouts", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "parent_id"
    t.string "app_layout"
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content"
    t.text "css"
    t.text "js"
    t.integer "position", default: 0, null: false
    t.boolean "is_shared", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["parent_id", "position"], name: "index_comfy_cms_layouts_on_parent_id_and_position"
    t.index ["site_id", "identifier"], name: "index_comfy_cms_layouts_on_site_id_and_identifier", unique: true
  end

  create_table "comfy_cms_pages", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.integer "layout_id"
    t.integer "parent_id"
    t.integer "target_page_id"
    t.string "label", null: false
    t.string "slug"
    t.string "full_path", null: false
    t.text "content_cache"
    t.integer "position", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.boolean "is_published", default: true, null: false
    t.boolean "is_shared", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["parent_id", "position"], name: "index_comfy_cms_pages_on_parent_id_and_position"
    t.index ["site_id", "full_path"], name: "index_comfy_cms_pages_on_site_id_and_full_path"
  end

  create_table "comfy_cms_revisions", id: :serial, force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.text "data"
    t.datetime "created_at"
    t.index ["record_type", "record_id", "created_at"], name: "index_cms_revisions_on_rtype_and_rid_and_created_at"
  end

  create_table "comfy_cms_sites", id: :serial, force: :cascade do |t|
    t.string "label", null: false
    t.string "identifier", null: false
    t.string "hostname", null: false
    t.string "path"
    t.string "locale", default: "en", null: false
    t.boolean "is_mirrored", default: false, null: false
    t.index ["hostname"], name: "index_comfy_cms_sites_on_hostname"
    t.index ["is_mirrored"], name: "index_comfy_cms_sites_on_is_mirrored"
  end

  create_table "comfy_cms_snippets", id: :serial, force: :cascade do |t|
    t.integer "site_id", null: false
    t.string "label", null: false
    t.string "identifier", null: false
    t.text "content"
    t.integer "position", default: 0, null: false
    t.boolean "is_shared", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["site_id", "identifier"], name: "index_comfy_cms_snippets_on_site_id_and_identifier", unique: true
    t.index ["site_id", "position"], name: "index_comfy_cms_snippets_on_site_id_and_position"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "crops", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "en_wikipedia_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.integer "parent_id"
    t.integer "plantings_count", default: 0
    t.integer "creator_id"
    t.integer "requester_id"
    t.string "approval_status", default: "approved"
    t.text "reason_for_rejection"
    t.text "request_notes"
    t.text "rejection_notes"
    t.boolean "perennial", default: false
    t.integer "median_lifespan"
    t.integer "median_days_to_first_harvest"
    t.integer "median_days_to_last_harvest"
    t.index ["name"], name: "index_crops_on_name"
    t.index ["requester_id"], name: "index_crops_on_requester_id"
    t.index ["slug"], name: "index_crops_on_slug", unique: true
  end

  create_table "crops_posts", id: false, force: :cascade do |t|
    t.integer "crop_id"
    t.integer "post_id"
    t.index ["crop_id", "post_id"], name: "index_crops_posts_on_crop_id_and_post_id"
    t.index ["crop_id"], name: "index_crops_posts_on_crop_id"
  end

  create_table "follows", id: :serial, force: :cascade do |t|
    t.integer "follower_id"
    t.integer "followed_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.integer "owner_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.index ["slug"], name: "index_forums_on_slug", unique: true
  end

  create_table "garden_types", force: :cascade do |t|
    t.text "name", null: false
    t.text "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gardens", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "owner_id"
    t.string "slug", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.boolean "active", default: true
    t.string "location"
    t.float "latitude"
    t.float "longitude"
    t.decimal "area"
    t.string "area_unit"
    t.integer "garden_type_id"
    t.index ["garden_type_id"], name: "index_gardens_on_garden_type_id"
    t.index ["owner_id"], name: "index_gardens_on_owner_id"
    t.index ["slug"], name: "index_gardens_on_slug", unique: true
  end

  create_table "gardens_photos", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "garden_id"
    t.index ["garden_id", "photo_id"], name: "index_gardens_photos_on_garden_id_and_photo_id"
  end

  create_table "harvests", id: :serial, force: :cascade do |t|
    t.integer "crop_id", null: false
    t.integer "owner_id", null: false
    t.date "harvested_at"
    t.decimal "quantity"
    t.string "unit"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.decimal "weight_quantity"
    t.string "weight_unit"
    t.integer "plant_part_id"
    t.float "si_weight"
    t.integer "planting_id"
    t.index ["planting_id"], name: "index_harvests_on_planting_id"
  end

  create_table "harvests_photos", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "harvest_id"
    t.index ["harvest_id", "photo_id"], name: "index_harvests_photos_on_harvest_id_and_photo_id"
  end

  create_table "likes", id: :serial, force: :cascade do |t|
    t.integer "member_id"
    t.string "likeable_type"
    t.integer "likeable_id"
    t.string "categories", array: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["likeable_id"], name: "index_likes_on_likeable_id"
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable_type_and_likeable_id"
    t.index ["member_id"], name: "index_likes_on_member_id"
  end

  create_table "median_functions", id: :serial, force: :cascade do |t|
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "login_name"
    t.string "slug"
    t.boolean "tos_agreement"
    t.boolean "show_email"
    t.string "location"
    t.float "latitude"
    t.float "longitude"
    t.boolean "send_notification_email", default: true
    t.text "bio"
    t.integer "plantings_count"
    t.boolean "newsletter"
    t.boolean "send_planting_reminder", default: true
    t.string "preferred_avatar_uri"
    t.integer "gardens_count"
    t.integer "harvests_count"
    t.integer "seeds_count"
    t.datetime "deleted_at"
    t.integer "photos_count"
    t.integer "forums_count"
    t.index ["confirmation_token"], name: "index_members_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_members_on_deleted_at"
    t.index ["email"], name: "index_members_on_email", unique: true
    t.index ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_members_on_slug", unique: true
    t.index ["unlock_token"], name: "index_members_on_unlock_token", unique: true
  end

  create_table "members_roles", id: false, force: :cascade do |t|
    t.integer "member_id"
    t.integer "role_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "sender_id"
    t.integer "recipient_id", null: false
    t.string "subject"
    t.text "body"
    t.boolean "read", default: false
    t.integer "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders_products", id: false, force: :cascade do |t|
    t.integer "order_id"
    t.integer "product_id"
  end

  create_table "photographings", id: :serial, force: :cascade do |t|
    t.integer "photo_id", null: false
    t.integer "photographable_id", null: false
    t.string "photographable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "crop_id"
    t.index ["photographable_id", "photographable_type", "photo_id"], name: "items_to_photos_idx", unique: true
    t.index ["photographable_id", "photographable_type"], name: "photographable_idx"
  end

  create_table "photos", id: :serial, force: :cascade do |t|
    t.integer "owner_id", null: false
    t.string "thumbnail_url", null: false
    t.string "fullsize_url", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title", null: false
    t.string "license_name", null: false
    t.string "license_url"
    t.string "link_url", null: false
    t.string "flickr_photo_id"
    t.datetime "date_taken"
  end

  create_table "photos_plantings", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "planting_id"
  end

  create_table "photos_seeds", id: false, force: :cascade do |t|
    t.integer "photo_id"
    t.integer "seed_id"
    t.index ["seed_id", "photo_id"], name: "index_photos_seeds_on_seed_id_and_photo_id"
  end

  create_table "plant_parts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
  end

  create_table "plantings", id: :serial, force: :cascade do |t|
    t.integer "garden_id", null: false
    t.integer "crop_id", null: false
    t.date "planted_at"
    t.integer "quantity"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.string "sunniness"
    t.string "planted_from"
    t.integer "owner_id"
    t.boolean "finished", default: false, null: false
    t.date "finished_at"
    t.integer "lifespan"
    t.integer "days_to_first_harvest"
    t.integer "days_to_last_harvest"
    t.integer "parent_seed_id"
    t.integer "harvests_count", default: 0
    t.index ["slug"], name: "index_plantings_on_slug", unique: true
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.integer "forum_id"
    t.index ["created_at", "author_id"], name: "index_posts_on_created_at_and_author_id"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "slug"
    t.index ["slug"], name: "index_roles_on_slug", unique: true
  end

  create_table "scientific_names", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.integer "crop_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "creator_id"
  end

  create_table "seeds", id: :serial, force: :cascade do |t|
    t.integer "owner_id", null: false
    t.integer "crop_id", null: false
    t.text "description"
    t.integer "quantity"
    t.date "plant_before"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "tradable_to", default: "nowhere"
    t.string "slug"
    t.integer "days_until_maturity_min"
    t.integer "days_until_maturity_max"
    t.text "organic", default: "unknown"
    t.text "gmo", default: "unknown"
    t.text "heirloom", default: "unknown"
    t.boolean "finished", default: false
    t.date "finished_at"
    t.integer "parent_planting_id"
    t.index ["slug"], name: "index_seeds_on_slug", unique: true
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "seed_id"
    t.bigint "requested_by_id"
    t.boolean "accepted"
    t.text "message"
    t.text "address_for_delivery"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requested_by_id"], name: "index_trades_on_requested_by_id"
    t.index ["seed_id"], name: "index_trades_on_seed_id"
  end

  add_foreign_key "harvests", "plantings"
  add_foreign_key "photographings", "crops"
  add_foreign_key "photographings", "photos"
  add_foreign_key "plantings", "seeds", column: "parent_seed_id", name: "parent_seed", on_delete: :nullify
  add_foreign_key "seeds", "plantings", column: "parent_planting_id", name: "parent_planting", on_delete: :nullify
  add_foreign_key "trades", "members", column: "requested_by_id"
  add_foreign_key "trades", "seeds"
end
