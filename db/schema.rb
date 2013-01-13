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

ActiveRecord::Schema.define(:version => 20130113060852) do

  create_table "crops", :force => true do |t|
    t.string   "system_name",      :null => false
    t.string   "en_wikipedia_url"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "slug"
  end

  add_index "crops", ["slug"], :name => "index_crops_on_slug", :unique => true
  add_index "crops", ["system_name"], :name => "index_crops_on_system_name"

  create_table "gardens", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "member_id"
    t.string   "slug",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "gardens", ["member_id"], :name => "index_gardens_on_user_id"
  add_index "gardens", ["slug"], :name => "index_gardens_on_slug", :unique => true

  create_table "members", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "username"
    t.string   "slug"
    t.boolean  "tos_agreement"
  end

  add_index "members", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "members", ["email"], :name => "index_users_on_email", :unique => true
  add_index "members", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "members", ["slug"], :name => "index_users_on_slug", :unique => true
  add_index "members", ["unlock_token"], :name => "index_users_on_unlock_token", :unique => true

  create_table "plantings", :force => true do |t|
    t.integer  "garden_id",   :null => false
    t.integer  "crop_id",     :null => false
    t.datetime "planted_at"
    t.integer  "quantity"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "posts", :force => true do |t|
    t.integer  "member_id",  :null => false
    t.string   "subject",    :null => false
    t.text     "body",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "slug"
  end

  add_index "posts", ["created_at", "member_id"], :name => "index_updates_on_created_at_and_user_id"
  add_index "posts", ["slug"], :name => "index_updates_on_slug", :unique => true

  create_table "scientific_names", :force => true do |t|
    t.string   "scientific_name", :null => false
    t.integer  "crop_id",         :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
