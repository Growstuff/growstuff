# frozen_string_literal: true

# Jobs other gardeners finished, now and at this time of year in earlier years,
# when enough of them did the same one. Only finished jobs count, and only those
# the gardeners made themselves, not from a template. The same job is the same
# name, whatever the case, about the same crop. A subclass says whose jobs to look
# at, and which crops, with #owner_ids and #crop_ids.
class JobIdeas
  class OthersJobs
    include PastYears

    # Fewer gardeners than this is not a trend, just someone's job.
    MIN_GARDENERS = 3
    MAX_IDEAS = 5
    CROP_ID = "COALESCE(CASE WHEN jobs.jobbable_type = 'Crop' THEN jobs.jobbable_id END, plantings.crop_id, seeds.crop_id)"
    WITHIN = '(jobs.finished_at BETWEEN ? AND ? OR (jobs.finished_at IS NULL AND jobs.due_date BETWEEN ? AND ?))'
    Row = Struct.new(:name, :owner_id, :crop_id, :on)

    def initialize(member, today)
      @member = member
      @today = today
    end

    def ideas
      return [] if owner_ids&.empty? || crop_ids&.empty?

      crops = Crop.where(id: grouped.keys.filter_map(&:last)).index_by(&:id)
      grouped.filter_map { |(_name, crop_id), rows| idea_for(rows, crops[crop_id]) }.max_by(MAX_IDEAS, &:gardeners)
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
    def growing(_crop)
      nil
    end

    def idea_for(rows, crop)
      return if open_names.include?(rows.first.name.downcase)

      now, earlier = rows.partition { |row| row.on > @today - WINDOW }
      owners = [now, earlier].map { |group| group.map(&:owner_id).uniq.size }
      period, gardeners = owners.first >= MIN_GARDENERS ? [:now, owners.first] : [:earlier, owners.last]
      return if gardeners < MIN_GARDENERS

      Idea.new(kind:, key: "#{kind}:#{rows.first.name.downcase}:#{crop&.id}", name: rows.first.name, crop:, gardeners:,
               period:, of: growing(crop), on: rows.map(&:on).max)
    end

    def grouped
      @grouped ||= rows.group_by { |row| [row.name.downcase, row.crop_id] }
    end

    def rows
      jobs = Job.where(finished: true, crop_job_step_id: nil).where.not(owner_id: left_out_ids)
      jobs = jobs.where(owner_id: owner_ids) if owner_ids
      jobs = jobs.where("#{CROP_ID} IN (?)", crop_ids) if crop_ids
      jobs.joins("LEFT JOIN plantings ON jobs.jobbable_type = 'Planting' AND plantings.id = jobs.jobbable_id")
        .joins("LEFT JOIN seeds ON jobs.jobbable_type = 'Seed' AND seeds.id = jobs.jobbable_id")
        .where(in_windows, *window_values)
        .pluck('jobs.name', 'jobs.owner_id', 'jobs.finished_at', 'jobs.due_date', Arel.sql(CROP_ID))
        .map { |name, owner_id, finished_at, due_date, crop_id| Row.new(name, owner_id, crop_id, finished_at&.to_date || due_date) }
    end

    # Now, and the same fortnight in each earlier year.
    def windows
      [(@today - WINDOW)..@today] + past_windows
    end

    def in_windows
      windows.map { WITHIN }.join(' OR ')
    end

    def window_values
      windows.flat_map { |window| [window.first.beginning_of_day, window.last.end_of_day, window.first, window.last] }
    end

    # Themselves, and the people they have blocked.
    def left_out_ids
      [@member.id] + @member.blocks.pluck(:blocked_id)
    end

    def open_names
      @open_names ||= @member.jobs.active.pluck(:name).map(&:downcase)
    end
  end
end
