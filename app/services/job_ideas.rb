# frozen_string_literal: true

# Jobs a member might like to add: what a crop's template would add to a
# planting they have, and what they did or planted at this time of year before.
# Each idea has a key that says what it is, so one the member has said is not for
# them stays hidden for a while.
class JobIdeas
  # How many ideas are suggested at a time.
  SHOWN = 5

  # Where an idea came from is its kind. The rest is what the kind has to say:
  # - planting and template: the planting it is for; a template idea also has the
  #   template and its schedule, the jobs it would add with their days
  # - on: the latest day it was done or planted at this time of year, and years how
  #   many years; for a harvest, the day it was last harvested from or, if never,
  #   expected to be ready, as period says
  # - gardeners: from other gardeners, how many did it, of how many grow the crop,
  #   now or in earlier years, as period says
  Idea = Struct.new(:kind, :key, :name, :crop, :planting, :template, :schedule, :on, :years, :gardeners, :of, :period,
                    keyword_init: true)

  # Sources a member can switch off, by name, and the ones each name stands for.
  # Templates and harvests are the member's own garden, so they are always on.
  SWITCHES = { 'mine' => %i(past_jobs past_plantings), 'community' => %i(community), 'nearby' => %i(nearby), 'world' => %i(world) }.freeze

  # How many ideas a member has, for the box over their jobs. It looks at other
  # people's jobs, so it is kept for a few minutes, until the member adds or hides
  # an idea.
  def self.count_for(member)
    Rails.cache.fetch(['job_ideas_count', member.id], expires_in: 10.minutes) { new(member).ideas.size }
  end

  def self.forget_count(member)
    Rails.cache.delete(['job_ideas_count', member.id])
  end

  def initialize(member, today: Time.zone.today, skip: [])
    @member = member
    @today = today
    @skipped = SWITCHES.values_at(*Array(skip)).flatten.compact
  end

  # Every idea not hidden, one source at a time in turn, so no one source fills
  # the list.
  def ideas
    @ideas ||= take_turns(sources.map { |source| source.ideas.select { |idea| hidden_keys.exclude?(idea.key) } })
  end

  # The few to suggest now. Dismissing one brings the next.
  def shown
    ideas.first(SHOWN)
  end

  def more
    ideas.size - shown.size
  end

  private

  def take_turns(lists)
    Array.new(lists.map(&:size).max.to_i) { |index| lists.filter_map { |list| list[index] } }.flatten
  end

  def sources
    {
      templates: JobIdeas::Templates, past_jobs: JobIdeas::PastJobs, past_plantings: JobIdeas::PastPlantings,
      harvest: JobIdeas::Harvest, community: JobIdeas::Community, nearby: JobIdeas::Nearby,
      world: JobIdeas::World
    }.except(*@skipped).values.map { |source| source.new(@member, @today) }
  end

  def hidden_keys
    @hidden_keys ||= @member.job_idea_dismissals.hiding.pluck(:key).to_set
  end
end
