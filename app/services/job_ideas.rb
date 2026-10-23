# frozen_string_literal: true

# Jobs a member might like to add: what a crop's template would add to a
# planting they have, and what they did or planted at this time of year before.
# Each idea has a key that says what it is, so one the member has said is not for
# them stays hidden for a while.
class JobIdeas
  # How many ideas are suggested at a time.
  SHOWN = 5

  # kind is where the idea came from. job_count is how many jobs a template would
  # add; on is the latest day it was done or planted at this time of year, and
  # years how many years it was. From other gardeners, gardeners is how many did
  # it, of how many grow the crop, now or in earlier years, as period says.
  Idea = Struct.new(:kind, :key, :name, :crop, :planting, :template, :job_count, :on, :years, :gardeners, :of, :period, keyword_init: true)

  def initialize(member, today: Time.zone.today)
    @member = member
    @today = today
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
    [JobIdeas::Templates.new(@member, @today), JobIdeas::PastJobs.new(@member, @today),
     JobIdeas::PastPlantings.new(@member, @today), JobIdeas::Community.new(@member, @today),
     JobIdeas::Nearby.new(@member, @today)]
  end

  def hidden_keys
    @hidden_keys ||= @member.job_idea_dismissals.hiding.pluck(:key)
  end
end
