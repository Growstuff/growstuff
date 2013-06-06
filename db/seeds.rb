# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# import crops from CSV

require 'csv'

puts "Loading crops..."
CSV.foreach(Rails.root.join('db', 'seeds', 'crops.csv')) do |row|
  system_name,scientific_name,en_wikipedia_url = row
  @crop = Crop.create(:system_name => system_name, :en_wikipedia_url => en_wikipedia_url)
  @crop.scientific_names.create(:scientific_name => scientific_name)
end
puts "Finished loading crops"

if Rails.env.development? or Rails.env.test?
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

  puts "Creating admin role..."
  @admin = Role.create(:name => 'Admin')
  puts "Creating crop wrangler role..."
  @wrangler = Role.create(:name => 'Crop Wrangler')

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

  puts "Adding account types..."
  AccountType.create!(
    :name => "Free",
    :is_paid => false,
    :is_permanent_paid => false
  )
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
  AccountType.create!(
    :name => "Staff",
    :is_paid => true,
    :is_permanent_paid => true
  )

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

puts "Done!"

