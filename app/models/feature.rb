# frozen_string_literal: true

# Features admins can enable globally or grant to individual members in Flipper.
class Feature
  NAMES = %i(job_ideas enable_planting_reminders enable_harvest_reminders planting_weather garden_stall planting_codes).freeze

  attr_reader :name

  def self.all
    NAMES.map { |name| new(name) }
  end

  def self.find(name)
    feature = NAMES.find { |known| known.to_s == name.to_s }
    raise ActiveRecord::RecordNotFound unless feature

    new(feature)
  end

  def self.enabled?(name, member = nil)
    Flipper.enabled?(name, member)
  end

  def initialize(name)
    @name = name
  end

  def enabled?
    Flipper.enabled?(name)
  end

  def enabled=(on)
    # Disabling Flipper's boolean gate clears all gates, including actor grants.
    actors = Flipper[name].actors_value.to_a
    on ? Flipper.enable(name) : Flipper.disable(name)
    actors.each { |id| Flipper.enable_actor(name, Flipper::Actor.new(id)) }
  end

  def members
    ids = Flipper[name].actors_value.filter_map { |id| id.delete_prefix('Member;') if id.start_with?('Member;') }
    Member.where(id: ids).order(:login_name)
  end

  def enable_member(member)
    Flipper.enable_actor(name, member)
  end

  def disable_member(member)
    Flipper.disable_actor(name, member)
  end

  def to_param
    name.to_s
  end
end
