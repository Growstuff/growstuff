# frozen_string_literal: true

# The features admins can switch on and off, kept in Flipper. Each is off until
# an admin switches it on.
class Feature
  NAMES = %i(job_ideas enable_planting_reminders enable_harvest_reminders).freeze

  attr_reader :name

  def self.all
    NAMES.map { |name| new(name) }
  end

  def self.find(name)
    feature = NAMES.find { |known| known.to_s == name.to_s }
    raise ActiveRecord::RecordNotFound unless feature

    new(feature)
  end

  def self.enabled?(name)
    Flipper.enabled?(name)
  end

  def initialize(name)
    @name = name
  end

  def enabled?
    Flipper.enabled?(name)
  end

  def enabled=(on)
    on ? Flipper.enable(name) : Flipper.disable(name)
  end

  def to_param
    name.to_s
  end
end
