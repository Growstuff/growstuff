# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

require 'csv'

def load_data
  Crop.transaction do
    # for all Growstuff sites, including production ones
    load_roles
    create_cropbot
    load_crops
    load_plant_parts

    # We don't load these in an environment except development to
    # prevent creating users in the wild - especially admins - with
    # known passwords.
    if Rails.env.development?
      load_test_users
      load_admin_users
    end
  end

  puts "Done!"
end

def load_crops
  source_path = Rails.root.join('db', 'seeds')
  Dir.glob("#{source_path}/crops*.csv").each do |crop_file|
    puts "Loading crops from #{crop_file}..."
    CSV.foreach(crop_file) do |row|
      CsvImporter.new.import_crop(row)
    end
  end
  puts "Finished loading crops"
end

def load_roles
  puts "Creating admin role..."
  @admin = Role.create(name: 'Admin')
  puts "Creating crop wrangler role..."
  @wrangler = Role.create(name: 'Crop Wrangler')
end

def load_test_users # rubocop:disable Metrics/AbcSize
  puts "Loading test users..."

  # Open suburb csv
  source_path = Rails.root.join('db', 'seeds')
  begin
    suburb_file = File.open("#{source_path}/suburbs.csv")
  rescue StandardError
    puts "Warning: unable to open suburbs.csv"
  end

  # rake parameter (eg. 'rake db:seed member_size=10')
  member_size = ENV['member_size'] ? ENV['member_size'].to_i : 3

  (1..member_size).each do |i|
    @user = Member.new(
      login_name: "test#{i}",
      email: "test#{i}@example.com",
      password: "password#{i}",
      tos_agreement: true
    )
    @user.skip_confirmation!
    @user.save!

    # Populate member location and garden location
    if suburb_file
      suburb_file.pos = 0 if suburb_file.eof?
      row = CSV.parse(suburb_file.readline)

      suburb, _country, _state, latitude, longitude = row[0]
      # Using 'update_column' method instead of 'update' so that
      # it avoids accessing Geocoding service for faster processing
      @user.gardens.first.update_columns(location: suburb, latitude: latitude, longitude: longitude)
      @user.update_columns(location: suburb, latitude: latitude, longitude: longitude)
    end

    # Create a planting by the member
    Planting.create(
      owner_id: @user.id,
      garden_id: @user.gardens.first.id,
      planted_at: Time.zone.today,
      crop_id: Crop.find(i % Crop.all.size + 1).id,
      sunniness: select_random_item(Planting::SUNNINESS_VALUES),
      planted_from: select_random_item(Planting::PLANTED_FROM_VALUES)
    )
  end

  puts "Finished loading test users"
end

def load_admin_users
  puts "Adding admin and crop wrangler members..."
  @admin_user = Member.new(
    login_name: "admin1",
    email: "admin1@example.com",
    password: "password1",
    tos_agreement: true
  )
  @admin_user.skip_confirmation!
  @admin_user.roles << @admin
  @admin_user.save!

  @wrangler_user = Member.new(
    login_name: "wrangler1",
    email: "wrangler1@example.com",
    password: "password1",
    tos_agreement: true
  )
  @wrangler_user.skip_confirmation!
  @wrangler_user.roles << @wrangler
  @wrangler_user.save!
end

def create_cropbot
  @cropbot_user = Member.new(
    login_name: "cropbot",
    email: Growstuff::Application.config.bot_email,
    password: SecureRandom.urlsafe_base64(64),
    tos_agreement: true
  )
  @cropbot_user.skip_confirmation!
  @cropbot_user.roles << @wrangler
  @cropbot_user.save!
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
    PlantPart.find_or_create_by!(name: pp)
  end
end

def select_random_item(array)
  array[rand(0..array.size - 1) % array.size]
end

load_data
