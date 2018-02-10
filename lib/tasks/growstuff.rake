namespace :growstuff do
  desc "Add an admin user, by name"
  # usage: rake growstuff:admin_user name=skud

  task admin_user: :environment do
    add_role_to_member! ENV['name'], 'admin'
  end

  desc "Add a crop wrangler user, by name"
  # usage: rake growstuff:cropwrangler_user name=skud

  task cropwrangler_user: :environment do
    add_role_to_member! ENV['name'], 'crop-wrangler'
  end

  def add_role_to_member!(login_name, role_name)
    unless login_name && role_name
      raise "Usage: rake growstuff:[rolename] name=[username] "\
        "\n (login name is case-sensitive)\n"
    end
    member = Member.find_by!(login_name: login_name)
    role = Role.find_by!(name: role_name)
    member.roles << role
  end

  desc "Upload crops from a CSV file"
  # usage: rake growstuff:import_crops file=filename.csv

  task import_crops: :environment do
    require 'csv'

    @file = ENV['file'] or raise "Usage: rake growstuff:import_crops file=file.csv"

    puts "Loading crops from #{@file}..."
    CSV.foreach(@file) do |row|
      CsvImporter.new.import_crop(row)
    end
    Rails.cache.delete('full_crop_hierarchy')
    puts "Finished loading crops"
  end

  desc "Send planting reminder email"
  # usage: rake growstuff:send_planting_reminder

  task send_planting_reminder: :environment do
    # Heroku scheduler only lets us run things daily, so this checks
    # whether it's the right day to actually do the deed.
    # Note that Heroku scheduler runs on UTC.
    # We'd like to send on Wednesday mornings, US time, which will be
    # very early Wednesday morning UTC.
    send_on_day = 3 # wednesday
    every_n_weeks = 2 # send fortnightly

    if (Time.zone.today.cwday == send_on_day) && (Time.zone.today.cweek % every_n_weeks == 0)
      Member.confirmed.find_each do |m|
        Notifier.planting_reminder(m).deliver_now!
      end
    end
  end

  desc "Depopulate Null Island"
  # this fixes up anyone who has erroneously wound up with a 0,0 lat/long
  task depopulate_null_island: :environment do
    Member.find_each do |m|
      if m.location && (m.latitude.nil? && m.longitude.nil?)
        m.geocode
        m.save
      end
    end
  end

  desc "One-off tasks needed at various times and kept for posterity"
  namespace :oneoff do
    desc "May 2013: replace any empty notification subjects with (no subject)"
    task empty_subjects: :environment do
      # this is inefficient as it checks every Notification, but the
      # site is small and there aren't many of them, so it shouldn't matter
      # for this one-off script.
      Notification.all.each do |n|
        n.replace_blank_subject
        n.save
      end
    end

    desc "May 2013: replace any empty garden names with Garden"
    task empty_garden_names: :environment do
      # this is inefficient as it checks every Garden, but the
      # site is small and there aren't many of them, so it shouldn't matter
      # for this one-off script.
      Garden.all.each do |g|
        if g.name.nil? || g.name =~ /^\s*$/
          g.name = "Garden"
          g.save
        end
      end
    end

    desc "July 2013: replace nil seed.tradable_to with nowhere"
    task tradable_to_nowhere: :environment do
      Seed.all.each do |s|
        unless s.tradable_to
          s.tradable_to = 'nowhere'
          s.save
        end
      end
    end

    desc "August 2013: set up plantings_count cache on crop"
    task reset_crop_plantings_count: :environment do
      Crop.find_each do |c|
        Crop.reset_counters c.id, :plantings
      end
    end

    desc "August 2013: set default creator on existing crops"
    task set_default_crop_creator: :environment do
      cropbot = Member.find_by(login_name: "cropbot")
      raise "cropbot not found: create cropbot member on site or run rake db:seed" unless cropbot
      Crop.find_each do |crop|
        unless crop.creator
          crop.creator = cropbot
          crop.save
        end
      end
      ScientificName.find_each do |sn|
        unless sn.creator
          sn.creator = cropbot
          sn.save
        end
      end
    end

    desc "August 2013: set planting owner"
    task set_planting_owner: :environment do
      Planting.find_each do |p|
        p.owner = p.garden.owner
        p.save
      end
    end

    desc "August 2013: initialize member planting counter"
    task initialize_member_planting_count: :environment do
      Member.find_each do |m|
        Member.reset_counters m.id, :plantings
      end
    end

    desc "October 2013: set garden locations to member locations"
    task initialize_garden_locations: :environment do
      Member.located.find_each do |m|
        m.gardens.each do |g|
          next if g.location.present?
          g.location = m.location
          g.latitude = m.latitude
          g.longitude = m.longitude
          g.save
        end
      end
    end

    desc "October 2013: import initial plant parts"
    task import_plant_parts: :environment do
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

    desc "July 2014: set planting_count to 0 by default, not nil"
    task zero_plantings_count: :environment do
      Crop.find_each do |c|
        if c.plantings_count.nil?
          c.plantings_count = 0
          c.save
        end
      end
    end

    desc "August 2014: fix ping to pint in database"
    task ping_to_pint: :environment do
      Harvest.find_each do |h|
        if h.unit == "ping"
          h.unit = "pint"
          h.save
        end
      end
    end

    desc "October 2014: remove unused photos"
    task remove_unused_photos: :environment do
      Photo.find_each(&:destroy_if_unused)
    end

    desc "October 2014: generate crops_posts records for existing posts"
    task generate_crops_posts_records: :environment do
      Post.find_each(&:save)
    end

    desc "October 2014: add alternate names for crops"
    task add_alternate_names: :environment do
      require 'csv'
      file = "db/seeds/alternate_names_201410.csv"
      puts "Loading alternate names from #{file}..."
      cropbot = Member.find_by(login_name: "cropbot")
      CSV.foreach(file) do |row|
        _crop_id, crop_name, alternate_names = row
        next if alternate_names.blank?
        crop = Crop.find_by(name: crop_name)
        if crop
          alternate_names.split(/,\s*/).each do |an|
            AlternateName.where(
              name: an,
              crop_id: crop.id
            ).first_or_create do |x|
              x.creator = cropbot
            end
          end
        end
      end
    end

    desc "January 2015: fill in si_weight column"
    task populate_si_weight: :environment do
      Harvest.find_each do |h|
        h.set_si_weight
        h.save
      end
    end

    desc "January 2015: build Elasticsearch index"
    task elasticsearch_create_index: :environment do
      Crop.__elasticsearch__.create_index! force: true
      Crop.import
    end
  end # end oneoff section
end
