# frozen_string_literal: true

namespace :gardens do

  desc "Mark old gardens inactive"
  task archive: :environment do
    Planting.archive!
    Garden.archive!
  end
end
