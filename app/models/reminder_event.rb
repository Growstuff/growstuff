# frozen_string_literal: true

# A reminder email sent to a member, or a member unsubscribing from one. Kept so admins can see how many go out
# and how many people leave.
class ReminderEvent < ApplicationRecord
  KINDS = %w(planting_reminder harvest_reminder).freeze
  EVENTS = %w(sent unsubscribed).freeze

  belongs_to :member

  validates :kind, inclusion: { in: KINDS }
  validates :event, inclusion: { in: EVENTS }

  scope :of_kind, ->(kind) { where(kind: kind.to_s) }

  def self.sent!(member, kind)
    create!(member:, kind: kind.to_s, event: 'sent', created_at: Time.zone.now)
  end

  def self.unsubscribed!(member, kind)
    create!(member:, kind: kind.to_s, event: 'unsubscribed', created_at: Time.zone.now)
  end

  # How many of each event in each of the last `weeks` weeks (starting Monday, in UTC), as { week_start => { 'sent' => n,
  # 'unsubscribed' => n } }, newest week first. Weeks with nothing in them are left in, as zeros. UTC throughout, because
  # that is how the database groups them, whatever time zone the viewer is in.
  def self.weekly(kind, weeks: 12, today: Time.now.utc.to_date)
    first = today.beginning_of_week - (weeks - 1).weeks
    counts = of_kind(kind).where(created_at: first.in_time_zone('UTC')..).group("date_trunc('week', created_at)::date", :event).count
    (0...weeks).map { |back| today.beginning_of_week - back.weeks }.index_with do |week|
      EVENTS.index_with { |event| counts.fetch([week, event], 0) }
    end
  end
end
