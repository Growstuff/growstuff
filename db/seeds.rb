# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'csv'

def load_data
  Crop.transaction do
    # for all Growstuff sites, including production ones
    load_roles
    load_basic_account_types
    create_cropbot
    load_crops
    load_plant_parts

    # for development environments only
    if Rails.env.development?
      load_test_users
      load_admin_users
      load_paid_account_types
      load_products
    end
  end

  puts "Done!"
end

def load_crops
  source_path = Rails.root.join('db', 'seeds')
  Dir.glob("#{source_path}/crops*.csv").each do |crop_file|
    puts "Loading crops from #{crop_file}..."
    CSV.foreach(crop_file) do |row|
      Crop.create_from_csv(row, definitely_new=true)
    end
  end
  puts "Finished loading crops"
end

def load_roles
  puts "Creating admin role..."
  @admin = Role.create(:name => 'Admin')
  puts "Creating crop wrangler role..."
  @wrangler = Role.create(:name => 'Crop Wrangler')
end

def load_basic_account_types
  puts "Adding 'free' and 'staff' account types..."
  AccountType.create!(
    :name => "Free",
    :is_paid => false,
    :is_permanent_paid => false
  )
  AccountType.create!(
    :name => "Staff",
    :is_paid => true,
    :is_permanent_paid => true
  )
end

def load_test_users
  puts "Loading test users..."
  (1..3).each do |i|
    @user = Member.create(
        :login_name => "test#{i}",
        :email => "test#{i}@example.com",
        :password => "password#{i}",
        :tos_agreement => true
    )
    @user.confirm!
    @user.save!
  end
  puts "Finished loading test users"
end

def load_admin_users
  puts "Adding admin and crop wrangler members..."
  @admin_user = Member.create(
    :login_name => "admin1",
    :email => "admin1@example.com",
    :password => "password1",
    :tos_agreement => true
  )
  @admin_user.confirm!
  @admin_user.roles << @admin
  @admin_user.save!

  @wrangler_user = Member.create(
    :login_name => "wrangler1",
    :email => "wrangler1@example.com",
    :password => "password1",
    :tos_agreement => true
  )
  @wrangler_user.confirm!
  @wrangler_user.roles << @wrangler
  @wrangler_user.save!
end

def create_cropbot
  @cropbot_user = Member.create(
    :login_name => "cropbot",
    :email => Growstuff::Application.config.bot_email,
    :password => SecureRandom.urlsafe_base64(64),
    :tos_agreement => true
  )
  @cropbot_user.confirm!
  @cropbot_user.roles << @wrangler
  @cropbot_user.save!
  @cropbot_user.account.account_type = AccountType.find_by_name("Staff")
  @cropbot_user.account.save
end

def load_paid_account_types
  puts "Adding 'paid' and 'seed' account types..."
  @paid_account = AccountType.create!(
    :name => "Paid",
    :is_paid => true,
    :is_permanent_paid => false
  )
  @seed_account = AccountType.create!(
    :name => "Seed",
    :is_paid => true,
    :is_permanent_paid => true
  )
end

def load_products
  puts "Adding products..."
  Product.create!(
    :name => "Annual subscription",
    :description => "Paid account, 1 year",
    :min_price => 3000,
    :account_type_id => @paid_account.id,
    :paid_months => 12
  )
  Product.create!(
    :name => "Seed account",
    :description => "Paid account, in perpetuity",
    :min_price => 15000,
    :account_type_id => @seed_account.id,
  )
end

def load_plant_parts
  puts "Loading plant parts..."
  plant_parts = [
    'fruit',
    'flower',
    'seed',
    'pod',
    'leaf',
    'stem',
    'bark',
    'bulb',
    'root',
    'tuber',
    'whole plant',
    'other'
  ]
  plant_parts.each do |pp|
    PlantPart.find_or_create_by_name!(pp)
  end
end



load_data
