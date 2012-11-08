# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# import crops from CSV

require 'csv'

CSV.foreach(Rails.root.join('db', 'seeds', 'crops.csv')) do |row|
  system_name,scientific_name,en_wikipedia_url = row
  @crop = Crop.create(:system_name => system_name, :en_wikipedia_url => en_wikipedia_url)
  @crop.scientific_names.create(:scientific_name => scientific_name)
end
