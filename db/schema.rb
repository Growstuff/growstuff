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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130518000339) do

  create_table "account_details", :force => true do |t|
    t.integer  "member_id",       :null => false
    t.integer  "account_type_id"
    t.datetime "paid_until"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "account_types", :force => true do |t|
    t.string   "name",              :null => false
    t.boolean  "is_paid"
    t.boolean  "is_permanent_paid"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "authentications", :force => true do |t|
    t.integer  "member_id",  :null => false
    t.string   "provider",   :null => false
    t.string   "uid"
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "name"
  end

  add_index "authentications", ["member_id"], :name => "index_authentications_on_member_id"

  create_table "comments", :force => true do |t|
    t.integer  "post_id",    :null => false
    t.integer  "author_id",  :null => false
    t.text     "body",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "crops", :force => true do |t|
    t.string   "system_name",      :null => false
    t.string   "en_wikipedia_url"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "slug"
  end

  add_index "crops", ["slug"], :name => "index_crops_on_slug", :unique => true
  add_index "crops", ["system_name"], :name => "index_crops_on_system_name"

  create_table "forums", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description", :null => false
    t.integer  "owner_id",    :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "slug"
  end

  add_index "forums", ["slug"], :name => "index_forums_on_slug", :unique => true

  create_table "gardens", :force => true do |t|
    t.string   "name",        :null => false
    t.integer  "owner_id"
    t.string   "slug",        :null => false
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.text     "description"
  end

  add_index "gardens", ["owner_id"], :name => "index_gardens_on_user_id"
  add_index "gardens", ["slug"], :name => "index_gardens_on_slug", :unique => true

  create_table "members", :force => true do |t|
    t.string   "email",                   :default => "",   :null => false
    t.string   "encrypted_password",      :default => "",   :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",         :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "login_name"
    t.string   "slug"
    t.boolean  "tos_agreement"
    t.boolean  "show_email"
    t.string   "location"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "send_notification_email", :default => true
  end

  add_index "members", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "members", ["email"], :name => "index_users_on_email", :unique => true
  add_index "members", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "members", ["slug"], :name => "index_users_on_slug", :unique => true
  add_index "members", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  create_table "members_roles", :id => false, :force => true do |t|
    t.integer "member_id"
    t.integer "role_id"
  end

  create_table "notifications", :force => true do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id",                    :null => false
    t.string   "subject"
    t.text     "body"
    t.boolean  "read",         :default => false
    t.integer  "post_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "order_items", :force => true do |t|
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "price"
    t.integer  "quantity"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "orders", :force => true do |t|
    t.integer  "member_id",    :limit => 255, :null => false
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.datetime "completed_at"
  end

  create_table "orders_products", :id => false, :force => true do |t|
    t.integer "order_id"
    t.integer "product_id"
  end

  create_table "plantings", :force => true do |t|
    t.integer  "garden_id",   :null => false
    t.integer  "crop_id",     :null => false
    t.date     "planted_at"
    t.integer  "quantity"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "slug"
    t.string   "sunniness"
  end

  add_index "plantings", ["slug"], :name => "index_plantings_on_slug", :unique => true

  create_table "posts", :force => true do |t|
    t.integer  "author_id",  :null => false
    t.string   "subject",    :null => false
    t.text     "body",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "slug"
    t.integer  "forum_id"
  end

  add_index "posts", ["created_at", "author_id"], :name => "index_updates_on_created_at_and_user_id"
  add_index "posts", ["slug"], :name => "index_updates_on_slug", :unique => true

  create_table "products", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "description",     :null => false
    t.integer  "min_price",       :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "account_type_id"
    t.integer  "paid_months"
  end

  create_table "roles", :force => true do |t|
    t.string   "name",        :null => false
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "slug"
  end

  add_index "roles", ["slug"], :name => "index_roles_on_slug", :unique => true

  create_table "scientific_names", :force => true do |t|
    t.string   "scientific_name", :null => false
    t.integer  "crop_id",         :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
