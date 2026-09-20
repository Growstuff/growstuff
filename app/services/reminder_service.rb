# frozen_string_literal: true

class ReminderService
  include Rails.application.routes.url_helpers

  def initialize
    @bot = Member.find_by(login_name: 'cropbot') || Member.first
    @sitename = ENV.fetch('GROWSTUFF_SITE_NAME', 'Growstuff')
  end

  def send_planting_reminders
    # Send on Monday
    return unless Time.zone.today.wday == 1

    Member.confirmed.wants_reminders.find_each do |m|
      next if m.plantings.active.empty?

      subject = "Your #{Time.zone.today.strftime('%B %Y')} #{@sitename} progress report"
      body = generate_planting_reminder_body(m)

      Notification.create!(
        recipient: m,
        sender: @bot,
        subject: subject,
        body: body
      )
    end
  end

  def send_harvest_reminders
    # Send on Wednesday
    return unless Time.zone.today.wday == 3

    Member.confirmed.wants_harvest_reminders.find_each do |m|
      harvesting_plantings = m.plantings.active.select(&:harvest_in_next_week?)
      next if harvesting_plantings.empty?

      subject = I18n.t('notifier_mailer.harvest_reminder.subject', sitename: @sitename)
      body = generate_harvest_reminder_body(m, harvesting_plantings)

      Notification.create!(
        recipient: m,
        sender: @bot,
        subject: subject,
        body: body
      )
    end
  end

  private

  def generate_planting_reminder_body(member)
    late = []
    super_late = []
    harvesting = []
    others = []

    member.plantings.active.annual.each do |planting|
      if planting.finish_is_predicatable?
        if planting.super_late?
          super_late << planting
        elsif planting.late?
          late << planting
        elsif planting.harvest_time?
          harvesting << planting
        else
          others << planting
        end
      end
    end

    body = "Hello #{member.login_name},\n\n"
    body += "## Your Weekly #{@sitename} progress report\n\n"

    if harvesting.any?
      body += "### Ready to harvest\n"
      body += "Congratulations, you have plants ready to harvest\n\n"
      harvesting.each do |p|
        body += "* [#{p.crop}](#{planting_url(p, host: default_host)})\n"
      end
      body += "\n"
    end

    if others.any?
      body += "### Progress report\n\n"
      others.each do |p|
        body += "* [#{p.crop}](#{planting_url(p, host: default_host)}) is #{format('%.0f', p.percentage_grown)}% grown with #{(p.finish_predicted_at - Time.zone.today).to_i} days to go.\n"
      end
      body += "\n"
    end

    if late.any?
      body += "### Late\n"
      body += "These plantings are at the end of their lifecycle.\n\n"
      late.each do |p|
        body += "* [#{p.crop}](#{planting_url(p, host: default_host)})\n"
      end
      body += "\n"
    end

    if super_late.any?
      body += "### Super late\n"
      body += "We suspect the following plantings finished long ago and no longer need tracking. You can mark them as finished to stop tracking.\n\n"
      super_late.each do |p|
        body += "* [#{p.crop}](#{planting_url(p, host: default_host)}) planted on #{p.planted_at.to_date}\n"
      end
      body += "\n"
    end

    body += "Harvested anything lately? [Track your harvests here.](#{new_harvest_url(host: default_host)})\n\n"
    body += "Want to track and predict a planting in your garden? [Add a planting.](#{new_planting_url(host: default_host)})\n\n"
    body += "Track and predict your entire garden, and keep your garden records up to date at [your garden overview](#{member_gardens_url(member, host: default_host)}) and on [your profile page](#{member_url(member, host: default_host)})\n\n"
    body += "#### See you soon on #{@sitename}!"

    body
  end

  def generate_harvest_reminder_body(member, plantings)
    body = "Hello #{member.login_name},\n\n"
    body += "## #{I18n.t('notifier_mailer.harvest_reminder.heading')}\n\n"
    body += "#{I18n.t('notifier_mailer.harvest_reminder.intro')}\n\n"

    plantings.each do |p|
      body += "* [#{p.crop}](#{planting_url(p, host: default_host)})"
      body += " (Predicted harvest date: #{p.first_harvest_predicted_at.to_date})" if p.first_harvest_predicted_at
      body += "\n"
    end

    body += "\nHarvested anything lately? [Track your harvests here.](#{new_harvest_url(host: default_host)})\n\n"
    body += "Track and predict your entire garden, and keep your garden records up to date at [your garden overview](#{member_gardens_url(member, host: default_host)}) and on [your profile page](#{member_url(member, host: default_host)})\n\n"
    body += "#### See you soon on #{@sitename}!"

    body
  end

  def default_host
    ENV.fetch('GROWSTUFF_HOST', 'growstuff.org')
  end
end
