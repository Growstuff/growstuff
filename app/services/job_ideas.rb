# frozen_string_literal: true

# Jobs a member might like to add: what a crop's template would add to a
# planting they have, and what they did or planted at this time of year before.
# Each idea has a key that says what it is, so one the member has said is not for
# them stays hidden for a while.
class JobIdeas
  # kind is where the idea came from. job_count is how many jobs a template would
  # add; on is the latest day it was done or planted at this time of year, and
  # years how many years it was.
  Idea = Struct.new(:kind, :key, :name, :crop, :planting, :template, :job_count, :on, :years, keyword_init: true)

  def initialize(member, today: Time.zone.today)
    @member = member
    @today = today
  end

  def ideas
    @ideas ||= sources.flat_map(&:ideas).select { |idea| hidden_keys.exclude?(idea.key) }
  end

  private

  def sources
    [JobIdeas::Templates.new(@member, @today), JobIdeas::PastJobs.new(@member, @today),
     JobIdeas::PastPlantings.new(@member, @today)]
  end

  def hidden_keys
    @hidden_keys ||= @member.job_idea_dismissals.hiding.pluck(:key)
  end
end
