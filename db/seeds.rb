# frozen_string_literal: true

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

def load_test_users
  require "faker"
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
      login_name:    "test#{i}",
      email:         "test#{i}@example.com",
      password:      "password#{i}",
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
      @user.gardens.first.update_columns(location: suburb, latitude:, longitude:)
      @user.update_columns(location: suburb, latitude:, longitude:)
    end

    # Create a planting by the member
    10.times do |n|
      planting = Planting.create!(
        owner_id:     @user.id,
        garden_id:    @user.gardens.first.id,
        planted_at:   (n * 7).days.ago,
        crop_id:      Crop.find(((i + n) % Crop.all.size) + 1).id,
        sunniness:    select_random_item(Planting::SUNNINESS_VALUES),
        planted_from: select_random_item(Planting::PLANTED_FROM_VALUES)
      )
      photo = Photo.create!(
        owner:         @user,
        source:        'flickr',
        source_id:     1,
        title:         Faker::Movies::HarryPotter.quote,
        license_name:  "CC-BY",
        license_url:   "http://example.com/license.html",
        thumbnail_url: "https://picsum.photos/200?planting-#{planting.id}",
        fullsize_url:  "https://picsum.photos/600?planting-#{planting.id}",
        link_url:      Faker::Internet.url
      )
      planting.photos << photo
    end

    # Create an activity by the member
    3.times do |_n|
      Activity.create!(
        owner_id:    @user.id,
        garden_id:   @user.gardens.first.id,
        due_date:    Time.zone.today,
        name:        Faker::Book.title,
        category:    "Weeding",
        description: Faker::Lorem.paragraphs.join("\n")
      )
    end

    # Create a post by the member
    post = Post.create!(
      author_id: @user.id,
      subject:   Faker::Book.title,
      body:      Faker::Lorem.paragraphs.join("\n")
    )
    photo = Photo.create!(
      owner:         @user,
      source:        'flickr',
      source_id:     1,
      title:         Faker::Movies::HarryPotter.quote,
      license_name:  "CC-BY",
      license_url:   "http://example.com/license.html",
      thumbnail_url: "https://picsum.photos/200?post-#{post.id}",
      fullsize_url:  "https://picsum.photos/600?post-#{post.id}",
      link_url:      Faker::Internet.url
    )
    post.photos << photo

    2.times do
      harvest = Harvest.create!(
        crop:            @user.plantings.last.crop,
        planting:        @user.plantings.last,
        plant_part:      select_random_item(PlantPart.all.to_a),
        owner:           @user,
        harvested_at:    1.day.ago,
        quantity:        "3",
        unit:            "individual",
        weight_quantity: 6,
        weight_unit:     "kg",
        description:     Faker::Book.title
      )

      photo = Photo.create!(
        owner:         @user,
        source:        'flickr',
        source_id:     1,
        title:         Faker::Movies::HarryPotter.quote,
        license_name:  "CC-BY",
        license_url:   "http://example.com/license.html",
        thumbnail_url: "https://picsum.photos/200?harvest-#{harvest.id}",
        fullsize_url:  "https://picsum.photos/600?harvest-#{harvest.id}",
        link_url:      Faker::Internet.url
      )
      harvest.photos << photo
    end

    5.times do
      seed = Seed.create!(
        owner:           @user,
        crop:            @user.plantings.first.crop,
        description:     Faker::Book.title,
        quantity:        Faker::Number.number(digits: 3),
        tradable_to:     select_random_item(Seed::TRADABLE_TO_VALUES),
        organic:         select_random_item(Seed::ORGANIC_VALUES),
        gmo:             select_random_item(['certified GMO-free', 'non-certified GMO-free', 'GMO', 'unknown']), # Strangely, this doesn't want to work as Seed:GMO_VALUES
        heirloom:        select_random_item(Seed::HEIRLOOM_VALUES),
        parent_planting: @user.plantings.first
      )

      photo = Photo.create!(
        owner:         @user,
        source:        'flickr',
        source_id:     1,
        title:         Faker::Movies::HarryPotter.quote,
        license_name:  "CC-BY",
        license_url:   "http://example.com/license.html",
        thumbnail_url: "https://picsum.photos/200?seed-#{seed.id}",
        fullsize_url:  "https://picsum.photos/600?seed-#{seed.id}",
        link_url:      Faker::Internet.url
      )
      seed.photos << photo
    end
  end

  puts "Finished loading test users"
end

def load_admin_users
  puts "Adding admin and crop wrangler members..."
  @admin_user = Member.new(
    login_name:    "admin1",
    email:         "admin1@example.com",
    password:      "password1",
    tos_agreement: true
  )
  @admin_user.skip_confirmation!
  @admin_user.roles << @admin
  @admin_user.save!

  @wrangler_user = Member.new(
    login_name:    "wrangler1",
    email:         "wrangler1@example.com",
    password:      "password1",
    tos_agreement: true
  )
  @wrangler_user.skip_confirmation!
  @wrangler_user.roles << @wrangler
  @wrangler_user.save!
end

def create_cropbot
  return if Member.find_by(login_name: 'cropbot')

  @cropbot_user = Member.new(
    login_name:    "cropbot",
    email:         Rails.application.config.bot_email,
    password:      SecureRandom.urlsafe_base64(64),
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
