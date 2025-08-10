# frozen_string_literal: true

namespace :openfarm do
  desc "Retrieve crop info from open farm"
  # usage: rake growstuff:admin_user name=skud

  task import: :environment do
    Rails.logger = Logger.new(STDOUT)
    OpenfarmService.new.import!
  end
end
