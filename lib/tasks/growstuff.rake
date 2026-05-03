# frozen_string_literal: true

namespace :growstuff do
  desc "Add an admin user, by name"
  # usage: rake growstuff:admin_user name=skud

  task admin_user: :environment do
    add_role_to_member! ENV.fetch('name', nil), 'Admin'
  end

  desc "Add a crop wrangler user, by name"
  # usage: rake growstuff:cropwrangler_user name=skud

  task cropwrangler_user: :environment do
    add_role_to_member! ENV.fetch('name', nil), 'Crop Wrangler'
  end

  def add_role_to_member!(login_name, role_name)
    unless login_name && role_name
      raise "Usage: rake growstuff:[rolename] name=[username] " \
            "\n (login name is case-sensitive)\n"
    end
    member = Member.find_by!(login_name:)
    role = Role.find_by!(name: role_name)
    member.roles << role
  end

  desc "Upload crops from a CSV file"
  # usage: rake growstuff:import_crops file=filename.csv

  task import_crops: :environment do
    require 'csv'

    (@file = ENV.fetch('file', nil)) || raise("Usage: rake growstuff:import_crops file=file.csv")

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
    # Send on Monday
    if Time.zone.today.wday == 1
      Member.confirmed.wants_reminders.find_each do |m|
        NotifierMailer.planting_reminder(m).deliver_later unless m.plantings.active.empty?
      end
    end
  end

  desc "Send harvest reminder email"
  # usage: rake growstuff:send_harvest_reminders

  task send_harvest_reminders: :environment do
    # Heroku scheduler only lets us run things daily, so this checks
    # Send on Wednesday
    if Time.zone.today.wday == 3
      Member.confirmed.wants_harvest_reminders.find_each do |m|
        if m.plantings.active.any?(&:harvest_in_next_week?)
          NotifierMailer.harvest_reminder(m).deliver_later
        end
      end
    end
  end

  desc "Mark seeds as finished when plant-before date expires"
  # usage: rake growstuff:finish_expired_seeds
  task finish_expired_seeds: :environment do
    Seed.expired.find_each do |seed|
      seed.update(finished: true, finished_at: Time.zone.now)
    end
  end
end
