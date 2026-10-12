# frozen_string_literal: true

require 'faker'

# Builds the sample data. Locations and photos are filled in directly so
# nothing here calls the geocoder or Flickr.
class SampleData
  PLACES = [
    ['Wellington', -41.2866, 174.7756], ['Lower Hutt', -41.2092, 174.908], ['Porirua', -41.1339, 174.8409],
    ['Auckland', -36.8485, 174.7633], ['Christchurch', -43.5321, 172.6362], ['Dunedin', -45.8788, 170.5028],
    ['Hobart', -42.8821, 147.3272], ['Melbourne', -37.8136, 144.9631],
    ['London', 51.5074, -0.1278], ['Portland', 45.5152, -122.6784], ['Toronto', 43.6532, -79.3832]
  ].freeze

  def initialize(members:)
    @count = members
    @crops = Crop.approved.to_a
    @plant_parts = PlantPart.all.to_a
  end

  def load
    abort "No approved crops: run rake db:seed first" if @crops.empty?

    members = (1..@count).map { |number| member(number) }
    members.each { |member| fill_garden(member) }
    follow_each_other(members)
    puts "Sample data ready: #{@count} members"
  end

  private

  def member(number)
    login = "sample_#{number}"
    existing = Member.find_by(login_name: login)
    return existing if existing

    name, latitude, longitude = PLACES[number % PLACES.size]
    member = Member.new(login_name: login, email: "#{login}@example.com", password: "password#{number}", tos_agreement: true)
    member.skip_confirmation!
    member.save!
    member.update_columns(location: name, latitude:, longitude:)
    member.gardens.first.update_columns(location: name, latitude:, longitude:)
    member
  end

  def fill_garden(member)
    return if member.plantings.any?

    garden = member.gardens.first
    rand(6..16).times { planting(member, garden) }
    rand(0..3).times { harvest(member) }
    rand(1..4).times { seed(member) }
    rand(0..2).times { activity(member, garden) }
  end

  def planting(member, garden)
    planting = Planting.create!(
      owner: member, garden:, crop: @crops.sample,
      planted_at: rand(0..400).days.ago, quantity: rand(1..12),
      sunniness: Planting::SUNNINESS_VALUES.sample, planted_from: Planting::PLANTED_FROM_VALUES.sample
    )
    planting.photos << photo(member, "planting-#{planting.id}") if rand < 0.7
    planting
  end

  def harvest(member)
    planting = member.plantings.order(:planted_at).first
    harvest = Harvest.create!(
      crop: planting.crop, planting:, plant_part: @plant_parts.sample, owner: member,
      harvested_at: rand(0..60).days.ago, quantity: rand(1..10), unit: 'individual',
      weight_quantity: rand(1..8), weight_unit: 'kg', description: Faker::Food.dish
    )
    harvest.photos << photo(member, "harvest-#{harvest.id}")
  end

  def seed(member)
    seed = Seed.create!(
      owner: member, crop: @crops.sample, description: Faker::Food.description.truncate(120),
      quantity: rand(10..300), tradable_to: %w(locally nationally internationally).sample,
      organic: Seed::ORGANIC_VALUES.sample, gmo: Seed::GMO_VALUES.sample, heirloom: Seed::HEIRLOOM_VALUES.sample,
      finished: false
    )
    seed.photos << photo(member, "seed-#{seed.id}")
  end

  def activity(member, garden)
    Activity.create!(
      owner: member, garden:, due_date: rand(-10..30).days.from_now.to_date,
      name: "#{Faker::Verb.base.capitalize} the #{Faker::Food.vegetables.downcase}",
      category: "Weeding", description: Faker::Lorem.sentence
    )
  end

  def follow_each_other(members)
    members.each do |member|
      members.sample(rand(2..6)).each do |other|
        next if other == member

        Follow.find_or_create_by!(follower: member, followed: other)
      end
    end
  end

  def photo(member, tag)
    Photo.create!(
      owner: member, source: 'flickr', source_id: 1, title: Faker::Food.ingredient,
      license_name: "CC-BY", license_url: "http://example.com/license.html",
      thumbnail_url: "https://picsum.photos/seed/#{tag}/200", fullsize_url: "https://picsum.photos/seed/#{tag}/600",
      link_url: Faker::Internet.url
    )
  end
end
