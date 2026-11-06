# frozen_string_literal: true

# Jobs other gardeners have planned for this month, finished or not, and those they
# finished at this time of year in earlier years. Only those the gardeners made
# themselves count, not from a template. The same job is the same name, whatever
# the case, about the same crop. A subclass says whose jobs to look
# at, and which crops, with #owner_ids and #crop_ids.
class JobIdeas
  class OthersJobs
    include PastYears

    MAX_IDEAS = 5
    CROP_ID = "COALESCE(CASE WHEN jobs.jobbable_type = 'Crop' THEN jobs.jobbable_id END, plantings.crop_id, seeds.crop_id)"
    Row = Struct.new(:name, :owner_id, :crop_id, :on)

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      return [] if owner_ids&.empty? || crop_ids&.empty?

      found = candidates.max_by(MAX_IDEAS) { |candidate| candidate[:gardeners] }
      crops = Crop.where(id: found.filter_map { |candidate| candidate[:crop_id] }).index_by(&:id)
      found.map { |candidate| idea_for(candidate, crops[candidate[:crop_id]]) }
    end

    private

    # Whose jobs to look at: ids, or nil for any gardener.
    def owner_ids
      nil
    end

    # The crops the jobs must be about: ids, or nil for any job.
    def crop_ids
      nil
    end

    def kind
      raise NotImplementedError
    end

    # How many gardeners grow the crop, to say how many of them did it. Only
    # worth saying when the jobs are limited to those growing the crop.
    def growing(_crop_id)
      nil
    end

    # What each job done by enough gardeners comes to, before the crops are loaded.
    def candidates
      rows.group_by { |row| [row.name.downcase, row.crop_id] }.filter_map do |(name, crop_id), group|
        next if open_names.include?(name)

        now, earlier = group.partition { |row| this_month.cover?(row.on) }
        owners = [now, earlier].map { |found| found.map(&:owner_id).uniq.size }
        period, gardeners = owners.first.positive? ? [:now, owners.first] : [:earlier, owners.last]
        next if gardeners.zero?

        { name: group.first.name, crop_id:, period:, gardeners:, on: group.map(&:on).max }
      end
    end

    def idea_for(candidate, crop)
      Idea.new(kind:, key: "#{kind}:#{candidate[:name].downcase}:#{crop&.id}", name: candidate[:name], crop:,
               gardeners: candidate[:gardeners], period: candidate[:period], of: growing(crop&.id), on: candidate[:on])
    end

    def rows
      jobs = Job.where(crop_job_step_id: nil).where.not(owner_id: left_out_ids)
      jobs = jobs.where(owner_id: owner_ids) if owner_ids
      jobs = jobs.where("#{CROP_ID} IN (?)", crop_ids) if crop_ids
      jobs = jobs.joins("LEFT JOIN plantings ON jobs.jobbable_type = 'Planting' AND plantings.id = jobs.jobbable_id")
        .joins("LEFT JOIN seeds ON jobs.jobbable_type = 'Seed' AND seeds.id = jobs.jobbable_id")
      finished_in(jobs.where(finished: true), past_windows).or(jobs.where(due_date: this_month))
        .pluck('jobs.name', 'jobs.owner_id', 'jobs.finished_at', 'jobs.due_date', Arel.sql(CROP_ID))
        .map { |name, owner_id, finished_at, due_date, crop_id| Row.new(name, owner_id, crop_id, finished_at&.to_date || due_date) }
    end

    def this_month
      @today.all_month
    end

    # Themselves, and the people they have blocked.
    def left_out_ids
      @left_out_ids ||= [@member.id] + @member.blocks.pluck(:blocked_id)
    end
  end
end
