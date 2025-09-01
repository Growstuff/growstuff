# frozen_string_literal: true

namespace :photos do
  desc 'Removes references to photos that dont exist anymore (404)'
  task prune_404s: :environment do
    puts 'Checking for broken photo links...'
    Photo.find_each do |photo|
      puts "Checking #{photo.fullsize_url}..."
      uri = URI.parse(photo.fullsize_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      request = Net::HTTP::Head.new(uri.request_uri)
      response = http.request(request)
      if response.code == '404'
        puts "Photo #{photo.id} is broken, deleting."
        photo.destroy
      end
    end
    puts 'Done.'
  end
end
