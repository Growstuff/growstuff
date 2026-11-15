# frozen_string_literal: true

# What members have lately planted, harvested and put up for trade, newest
# first, as one list of events.
class RecentActivity
  Event = Struct.new(:member, :verb, :subject, :at, :following, keyword_init: true)

  def self.events(member_ids, following: false)
    return [] if member_ids.empty?

    events = events_from(Planting.where(owner_id: member_ids), 'planted', :planted_at, 10, following)
    events += events_from(Harvest.where(owner_id: member_ids), 'harvested', :harvested_at, 10, following)
    events += events_from(Seed.current.tradable.where(owner_id: member_ids), 'has seeds to trade:', :created_at, 5, following)
    events.compact.sort_by { |event| event.at || Time.zone.at(0) }.reverse
  end

  # The newest few of the records, each as an event at the time in the column.
  def self.events_from(records, verb, column, limit, following)
    records.includes(:owner, :crop).order(column => :desc).limit(limit).map do |record|
      Event.new(member: record.owner, verb:, subject: record.crop, at: record[column], following:)
    end
  end
  private_class_method :events_from
end
