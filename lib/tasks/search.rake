# frozen_string_literal: true

namespace :search do
  desc 'reindex'
  task reindex: :environment do
    Crop.reindex
    Planting.reindex
  end
end
