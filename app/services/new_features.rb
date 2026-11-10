# frozen_string_literal: true

# What we've added to the list of new features, and when, so the planting reminder can tell a member about whatever
# has come along since we last emailed them. Add a line, dated the day you add it here, when a feature ships; `path` is the name of
# the route helper (without `_url`) the email links to, or `:place` for the member's own place page.
class NewFeatures
  Feature = Data.define(:added_on, :title, :description, :path) do
    # Where the email sends a member to find the feature. `routes` is anything with the URL helpers, such as the view. The
    # place page needs a place, so a member who hasn't given a location gets the list of places instead.
    def url(member, routes)
      return routes.place_url(member.location) if path == :place && member.location.present?

      routes.public_send("#{path == :place ? :places : path}_url")
    end
  end

  ALL = [
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Seed library', path: :seeds,
                description: 'Keep track of the seeds you have, and find seeds other gardeners are sharing.'),
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Nursery garden', path: :nursery,
                description: 'Raise seedlings in a nursery, then transplant them into your gardens when they are ready.'),
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Jobs', path: :jobs,
                description: 'Plan the jobs your garden needs, with ideas for what to do and when.'),
    Feature.new(added_on: Date.new(2026, 10, 31), title: 'Weather data', path: :plantings,
                description: 'See the rain, temperature and soil temperature your plantings grew through.'),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Frost danger', path: :place,
                description: 'See when frost is usually a danger where you garden, and how each of your plantings sits against it.'),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Optimal climate for plantings', path: :plantings,
                description: "See whether the weather suits each planting's crop, with its best temperatures shown on the weather chart."),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Link plantings to their seeds', path: :plantings,
                description: 'Say which of your seeds a planting came from, and how it was started, from the planting page.'),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Seed packet data', path: :seeds,
                description: 'Save what the packet says, like how long it takes to germinate and to mature, on your seeds.'),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Volunteer plantings', path: :plantings,
                description: 'Say a planting is a volunteer, one that came up on its own, when you tell us how it started.'),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Growing requirements', path: :crops,
                description: 'See what a crop needs on its page, including soil pH, crop cycle, altitude and light, from EcoCrop.'),
    Feature.new(added_on: Date.new(2026, 11, 10), title: 'Gardens safe from frost', path: :gardens,
                description: 'Mark a garden as safe from frost, such as indoors or heated, so its plantings are not counted as at risk.')
  ].freeze

  # The features added after `date`, oldest first, and in the order they are listed for the same day.
  def self.since(date)
    ALL.select { |feature| feature.added_on > date.to_date }.sort_by.with_index { |feature, index| [feature.added_on, index] }
  end
end
