# frozen_string_literal: true

class BackfillMemberWeatherJob < ApplicationJob
  queue_as :default

  def perform(member_id)
    member = Member.find_by(id: member_id)
    WeatherUpdater.new.update_member(member) if member && Feature.enabled?(:planting_weather)
  end
end
