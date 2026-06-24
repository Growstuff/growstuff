# frozen_string_literal: true

namespace :search do
  desc 'reindex'
  task reindex: :environment do
    Crop.reindex
    Planting.reindex
    Harvest.reindex
  end
end
