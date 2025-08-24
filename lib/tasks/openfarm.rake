# frozen_string_literal: true

namespace :openfarm do
  desc "Retrieve crop info from open farm"
  # usage: rake growstuff:admin_user name=skud

  task import: :environment do
    Rails.logger = Logger.new(STDOUT)
    OpenfarmService.new.import!
  end

  desc "Delete all pictures with source OpenFarm or from legacy S3 URL"
  task delete_pictures: :environment do
    puts "Deleting pictures with source OpenFarm or from legacy S3 URL..."
    s3_legacy_url = 'https://s3.amazonaws.com/openfarm-project/%'
    photos_to_delete = Photo.where(source: 'openfarm')
                            .or(Photo.where('fullsize_url LIKE ?', s3_legacy_url))
    count = photos_to_delete.count
    photos_to_delete.each do |photo|
      photo.associations.each do |photo_association|
        photo_association.delete
      end
      photo.delete
    end
    puts "Deleted #{count} pictures."
  end
end
