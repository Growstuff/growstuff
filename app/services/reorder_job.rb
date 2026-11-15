# frozen_string_literal: true

# Only reorder jobs the member can edit, on the destination day. The normal
# created_at/id order breaks ties for jobs that have never been moved.
class ReorderJob
  def self.call(job, scope, before_id)
    jobs = scope.where(due_date: job.due_date).order(:position, :created_at, :id).lock.to_a
    jobs.reject! { |other| other.id == job.id }
    index = before_id.present? ? jobs.index { |other| other.id.to_s == before_id.to_s } : jobs.length
    return false unless index

    jobs.insert(index, job)
    jobs.each_with_index { |other, position| other.update!(position:) }
    true
  end
end
