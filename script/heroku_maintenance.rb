#!/usr/bin/env ruby

require 'platform-api'
require 'yaml'

heroku = PlatformAPI.connect(ENV['HEROKU_API_KEY'])
branch = ENV['TRAVIS_BRANCH']
travis_config = YAML.load_file('.travis.yml')
if travis_config['deploy']['app'].key? branch
  app = travis_config['deploy']['app'][branch]
else
  abort "No Heroku app found for branch #{branch}"
end

case ARGV[0]
when "on"
  maintenance_state = true
when "off"
  maintenance_state = false
else
  abort "usage: #{$PROGRAM_NAME} (on|off)"
end

puts "Turning #{maintenance_state} maintenance mode on app #{app}"
heroku.app.update app, maintenance: maintenance_state
