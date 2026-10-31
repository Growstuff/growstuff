# frozen_string_literal: true

# What we've added to the list of new features, and when, so the planting reminder can tell a member about whatever
# has come along since we last emailed them. Add a line, dated the day you add it here, when a feature ships; `path` is the name of
# the route helper (without `_url`) the email links to.
class NewFeatures
  Feature = Data.define(:added_on, :title, :description, :path)

  ALL = [
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Seed library', path: :seeds,
                description: 'Keep track of the seeds you have, and find seeds other gardeners are sharing.'),
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Nursery garden', path: :nursery,
                description: 'Raise seedlings in a nursery, then transplant them into your gardens when they are ready.'),
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Jobs', path: :jobs,
                description: 'Plan the jobs your garden needs, with ideas for what to do and when.'),
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Weather data', path: :plantings,
                description: 'See the rain, temperature and soil temperature your plantings grew through.')
  ].freeze

  # The features added after `date`, oldest first.
  def self.since(date)
    ALL.select { |feature| feature.added_on > date.to_date }.sort_by(&:added_on)
  end
end
