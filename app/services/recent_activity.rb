# frozen_string_literal: true

# What members have lately planted, harvested and put up for trade, newest
# first, as one list of events.
class RecentActivity
  Event = Struct.new(:member, :verb, :subject, :at, :following, keyword_init: true)

  def self.events(member_ids, following: false)
    return [] if member_ids.empty?

    events = Planting.where(owner_id: member_ids).includes(:owner, :crop).order(planted_at: :desc).limit(10).map do |planting|
      Event.new(member: planting.owner, verb: 'planted', subject: planting.crop, at: planting.planted_at, following:)
    end
    events += Harvest.where(owner_id: member_ids).includes(:owner, :crop).order(harvested_at: :desc).limit(10).map do |harvest|
      Event.new(member: harvest.owner, verb: 'harvested', subject: harvest.crop, at: harvest.harvested_at, following:)
    end
    seeds = Seed.current.tradable.where(owner_id: member_ids).includes(:owner, :crop).order(created_at: :desc).limit(5)
    events += seeds.map do |seed|
      Event.new(member: seed.owner, verb: 'has seeds to trade:', subject: seed.crop, at: seed.created_at, following:)
    end
    events.compact.sort_by { |event| event.at || Time.zone.at(0) }.reverse
  end
end
