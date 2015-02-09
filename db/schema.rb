# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150209105410) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_types", force: true do |t|
    t.string   "name",              null: false
    t.boolean  "is_paid"
    t.boolean  "is_permanent_paid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts", force: true do |t|
    t.integer  "member_id",       null: false
    t.integer  "account_type_id"
    t.datetime "paid_until"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "alternate_names", force: true do |t|
    t.string   "name",       null: false
    t.integer  "crop_id",    null: false
    t.integer  "creator_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authentications", force: true do |t|
    t.integer  "member_id",  null: false
    t.string   "provider",   null: false
    t.string   "uid"
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  add_index "authentications", ["member_id"], name: "index_authentications_on_member_id", using: :btree

  create_table "comments", force: true do |t|
    t.integer  "post_id",    null: false
    t.integer  "author_id",  null: false
    t.text     "body",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "crops", force: true do |t|
    t.string   "name",                                      null: false
    t.string   "en_wikipedia_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.integer  "parent_id"
    t.integer  "plantings_count",      default: 0
    t.integer  "creator_id"
    t.integer  "requester_id"
    t.string   "approval_status",      default: "approved"
    t.text     "reason_for_rejection"
    t.text     "request_notes"
    t.text     "rejection_notes"
  end

  add_index "crops", ["name"], name: "index_crops_on_name", using: :btree
  add_index "crops", ["requester_id"], name: "index_crops_on_requester_id", using: :btree
  add_index "crops", ["slug"], name: "index_crops_on_slug", unique: true, using: :btree

  create_table "crops_posts", id: false, force: true do |t|
    t.integer "crop_id"
    t.integer "post_id"
  end

  add_index "crops_posts", ["crop_id", "post_id"], name: "index_crops_posts_on_crop_id_and_post_id", using: :btree
  add_index "crops_posts", ["crop_id"], name: "index_crops_posts_on_crop_id", using: :btree

  create_table "follows", force: true do |t|
    t.integer  "follower_id"
    t.integer  "followed_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", force: true do |t|
    t.string   "name",        null: false
    t.text     "description", null: false
    t.integer  "owner_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "forums", ["slug"], name: "index_forums_on_slug", unique: true, using: :btree

  create_table "gardens", force: true do |t|
    t.string   "name",                       null: false
    t.integer  "owner_id"
    t.string   "slug",                       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.boolean  "active",      default: true
    t.string   "location"
    t.float    "latitude"
    t.float    "longitude"
    t.decimal  "area"
    t.string   "area_unit"
  end

  add_index "gardens", ["owner_id"], name: "index_gardens_on_owner_id", using: :btree
  add_index "gardens", ["slug"], name: "index_gardens_on_slug", unique: true, using: :btree

  create_table "gardens_photos", id: false, force: true do |t|
    t.integer "photo_id"
    t.integer "garden_id"
  end

  add_index "gardens_photos", ["garden_id", "photo_id"], name: "index_gardens_photos_on_garden_id_and_photo_id", using: :btree

  create_table "harvests", force: true do |t|
    t.integer  "crop_id",         null: false
    t.integer  "owner_id",        null: false
    t.date     "harvested_at"
    t.decimal  "quantity"
    t.string   "unit"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.decimal  "weight_quantity"
    t.string   "weight_unit"
    t.integer  "plant_part_id"
    t.float    "si_weight"
  end

  create_table "harvests_photos", id: false, force: true do |t|
    t.integer "photo_id"
    t.integer "harvest_id"
  end

  add_index "harvests_photos", ["harvest_id", "photo_id"], name: "index_harvests_photos_on_harvest_id_and_photo_id", using: :btree

  create_table "members", force: true do |t|
    t.string   "email",                   default: "",   null: false
    t.string   "encrypted_password",      default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",         default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login_name"
    t.string   "slug"
    t.boolean  "tos_agreement"
    t.boolean  "show_email"
    t.string   "location"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "send_notification_email", default: true
    t.text     "bio"
    t.integer  "plantings_count"
    t.boolean  "newsletter"
    t.boolean  "send_planting_reminder",  default: true
  end

  add_index "members", ["confirmation_token"], name: "index_members_on_confirmation_token", unique: true, using: :btree
  add_index "members", ["email"], name: "index_members_on_email", unique: true, using: :btree
  add_index "members", ["reset_password_token"], name: "index_members_on_reset_password_token", unique: true, using: :btree
  add_index "members", ["slug"], name: "index_members_on_slug", unique: true, using: :btree
  add_index "members", ["unlock_token"], name: "index_members_on_unlock_token", unique: true, using: :btree

  create_table "members_roles", id: false, force: true do |t|
    t.integer "member_id"
    t.integer "role_id"
  end

  create_table "notifications", force: true do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id",                 null: false
    t.string   "subject"
    t.text     "body"
    t.boolean  "read",         default: false
    t.integer  "post_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_items", force: true do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "price"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "completed_at"
    t.integer  "member_id"
    t.string   "paypal_express_token"
    t.string   "paypal_express_payer_id"
    t.string   "referral_code"
  end

  create_table "orders_products", id: false, force: true do |t|
    t.integer "order_id"
    t.integer "product_id"
  end

  create_table "photos", force: true do |t|
    t.integer  "owner_id",        null: false
    t.string   "thumbnail_url",   null: false
    t.string   "fullsize_url",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title",           null: false
    t.string   "license_name",    null: false
    t.string   "license_url"
    t.string   "link_url",        null: false
    t.string   "flickr_photo_id"
  end

  create_table "photos_plantings", id: false, force: true do |t|
    t.integer "photo_id"
    t.integer "planting_id"
  end

  create_table "plant_parts", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  create_table "plantings", force: true do |t|
    t.integer  "garden_id",                    null: false
    t.integer  "crop_id",                      null: false
    t.date     "planted_at"
    t.integer  "quantity"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.string   "sunniness"
    t.string   "planted_from"
    t.integer  "owner_id"
    t.boolean  "finished",     default: false
    t.date     "finished_at"
  end

  add_index "plantings", ["slug"], name: "index_plantings_on_slug", unique: true, using: :btree

  create_table "posts", force: true do |t|
    t.integer  "author_id",  null: false
    t.string   "subject",    null: false
    t.text     "body",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.integer  "forum_id"
    t.integer  "parent_id"
  end

  add_index "posts", ["created_at", "author_id"], name: "index_posts_on_created_at_and_author_id", using: :btree
  add_index "posts", ["slug"], name: "index_posts_on_slug", unique: true, using: :btree

  create_table "products", force: true do |t|
    t.string   "name",              null: false
    t.text     "description",       null: false
    t.integer  "min_price",         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "account_type_id"
    t.integer  "paid_months"
    t.integer  "recommended_price"
  end

  create_table "roles", force: true do |t|
    t.string   "name",        null: false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  add_index "roles", ["slug"], name: "index_roles_on_slug", unique: true, using: :btree

  create_table "scientific_names", force: true do |t|
    t.string   "scientific_name", null: false
    t.integer  "crop_id",         null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator_id"
  end

  create_table "seeds", force: true do |t|
    t.integer  "owner_id",                                    null: false
    t.integer  "crop_id",                                     null: false
    t.text     "description"
    t.integer  "quantity"
    t.date     "plant_before"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tradable_to",             default: "nowhere"
    t.string   "slug"
    t.integer  "days_until_maturity_min"
    t.integer  "days_until_maturity_max"
    t.text     "organic",                 default: "unknown"
    t.text     "gmo",                     default: "unknown"
    t.text     "heirloom",                default: "unknown"
  end

  add_index "seeds", ["slug"], name: "index_seeds_on_slug", unique: true, using: :btree

end
