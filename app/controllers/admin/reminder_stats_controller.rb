# frozen_string_literal: true

module Admin
  # How many reminder emails go out each week, and how many members unsubscribe from them.
  class ReminderStatsController < ApplicationController
    before_action :authenticate_member!
    before_action { authorize! :manage, :all }

    REMINDERS = {
      'planting_reminder' => { title: 'Planting reminders', setting: :send_planting_reminder, feature: :enable_planting_reminders },
      'harvest_reminder'  => { title: 'Harvest reminders', setting: :send_harvest_reminder, feature: :enable_harvest_reminders }
    }.freeze

    def index
      @reminders = REMINDERS.map do |kind, reminder|
        reminder.merge(kind:, weeks: ReminderEvent.weekly(kind), enabled: Feature.enabled?(reminder[:feature]),
                       subscribed: Member.confirmed.where(reminder[:setting] => true).count,
                       opted_out: Member.confirmed.where(reminder[:setting] => false).count,
                       last_sent_on: ReminderEvent.of_kind(kind).where(event: 'sent').maximum(:created_at))
      end
    end
  end
end
