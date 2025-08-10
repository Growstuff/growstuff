# frozen_string_literal: true

class PushNotificationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Member.where.not(timezone: nil).pluck(:timezone).uniq.each do |timezone|
      Time.use_zone(timezone) do
        if Time.zone.now.hour == 8
          Member.where(timezone: timezone).each do |member|
            send_planting_notifications(member)
            send_activity_notifications(member)
          end
        end
      end
    end
  end

  private

  def send_planting_notifications(member)
    member.plantings.active.annual.each do |planting|
      if planting.finish_is_predicatable? && (planting.late? || planting.super_late?)
        PushNotificationService.new(member, "Your #{planting.crop_name} planting is ready to be marked as finished.").send
      end
    end
  end

  def send_activity_notifications(member)
    due_activities = member.activities.where(due_date: Date.today, finished: false)
    due_activities.each do |activity|
      PushNotificationService.new(member, "Activity due: #{activity.name}").send
    end
  end
end
