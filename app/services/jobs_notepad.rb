# frozen_string_literal: true

# A member's jobs, ready to show as a notepad: on their jobs page, or, with a
# garden, just their jobs for that garden, on the garden's page.
class JobsNotepad
  def initialize(member, garden: nil, pinned: [])
    @member = member
    @garden = garden
    @pinned = pinned
  end

  # The jobs grouped by when they are for. See JobList.
  def groups
    JobList.new(jobs, pinned: @pinned).groups
  end

  def done_this_week
    scope.finished_this_week.count
  end

  private

  def jobs
    @jobs ||= scope.includes(:garden, :jobbable).order(Arel.sql('due_date IS NULL'), :due_date, :created_at, :id).to_a.tap do |jobs|
      preload_jobbables(jobs)
    end
  end

  def scope
    jobs = Job.where(owner: @member)
    @garden ? jobs.where(garden: @garden) : jobs
  end

  # The notepad shows a planting's crop and garden and a seed's crop. Rails can't
  # load through a link that may be a crop, planting or seed, so each kind is
  # loaded on its own, in one query rather than one per job.
  def preload_jobbables(jobs)
    linked = jobs.filter_map(&:jobbable)
    ActiveRecord::Associations::Preloader.new(records: linked.grep(Planting), associations: %i(crop garden)).call
    ActiveRecord::Associations::Preloader.new(records: linked.grep(Seed), associations: :crop).call
  end
end
