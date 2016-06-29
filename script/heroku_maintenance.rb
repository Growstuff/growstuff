#!/usr/bin/env ruby

require 'heroku-api'
require 'yaml'

heroku = Heroku::API.new(api_key: ENV['HEROKU_API_KEY'])
branch = ENV['TRAVIS_BRANCH']
travis_config = YAML.load_file('.travis.yml')
if travis_config['deploy']['app'].key? branch
  app = travis_config['deploy']['app'][branch]
else
  abort "No Heroku app found for branch #{branch}"
end

case ARGV[0]
when "on"
  maintenance_state = 1
when "off"
  maintenance_state = 0
else
  abort "usage: #{$0} (on|off)"
end

puts "Turning #{maintenance_state} maintenance mode on app #{app}"
heroku.post_app_maintenance(app, maintenance_state)
