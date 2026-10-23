# frozen_string_literal: true

# Jobs a member might like to add: what a crop's template would add to a
# planting they have, and what they did or planted around now last year. Each idea has a
# key that says what it is, so one the member has said is not for them stays
# hidden for a while.
class JobIdeas
  # kind is where the idea came from. job_count is how many jobs a template would
  # add; on is the day it was done or planted last year.
  Idea = Struct.new(:kind, :key, :name, :crop, :planting, :template, :job_count, :on, keyword_init: true)

  def initialize(member, today: Time.zone.today)
    @member = member
    @today = today
  end

  def ideas
    @ideas ||= sources.flat_map(&:ideas).select { |idea| hidden_keys.exclude?(idea.key) }
  end

  private

  def sources
    [JobIdeas::Templates.new(@member, @today), JobIdeas::LastYear.new(@member, @today),
     JobIdeas::PlantedLastYear.new(@member, @today)]
  end

  def hidden_keys
    @hidden_keys ||= @member.job_idea_dismissals.hiding.pluck(:key)
  end
end
