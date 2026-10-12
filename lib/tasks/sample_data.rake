# frozen_string_literal: true

namespace :growstuff do
  desc "Add lots of sample members, plantings, harvests and seeds to a development database"
  # usage: rake growstuff:sample_data [members=40]
  #
  # Safe to run more than once: members are named sample_1, sample_2 and so
  # on, and a member that already exists is left alone, so running it again
  # with a bigger number only adds the new ones.
  task sample_data: :environment do
    abort "growstuff:sample_data only runs in development" unless Rails.env.development?

    require Rails.root.join('lib/sample_data')

    SampleData.new(members: ENV.fetch('members', 40).to_i).load
  end
end
