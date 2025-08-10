# frozen_string_literal: true

namespace :openfarm do
  desc "Retrieve crop info from open farm"
  # usage: rake growstuff:admin_user name=skud

  task import: :environment do
    Rails.logger = Logger.new(STDOUT)
    OpenfarmService.new.import!
  end

  desc "Delete all pictures with source OpenFarm"
  task delete_pictures: :environment do
    puts "Deleting pictures with source OpenFarm..."
    photos_to_delete = Photo.where(source: 'openfarm')
    count = photos_to_delete.count
    photos_to_delete.destroy_all
    puts "Deleted #{count} pictures."
  end
end
