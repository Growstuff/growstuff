# frozen_string_literal: true

class Notifier < ApplicationMailer
  # include NotificationsHelper
  default from: "Growstuff <#{ENV['GROWSTUFF_EMAIL']}>"

  def verifier
    unless ENV['RAILS_SECRET_TOKEN']
      raise "RAILS_SECRET_TOKEN environment variable"\
        "not set - have you created config/application.yml?"
    end

    ActiveSupport::MessageVerifier.new(ENV['RAILS_SECRET_TOKEN'])
  end

  def notify(notification)
    @notification = notification
    @reply_link = reply_link(@notification)

    # Encrypting
    message = { member_id: @notification.recipient.id, type: :send_notification_email }
    @signed_message = verifier.generate(message)

    mail(to:      @notification.recipient.email,
         subject: @notification.subject)
  end

  def planting_reminder(member)
    @member = member
    @sitename = ENV['GROWSTUFF_SITE_NAME']

    @late = []
    @super_late = []
    @harvesting = []
    @others = []

    @member.plantings.active.annual.each do |planting|
      if planting.finish_is_predicatable?
        if planting.super_late?
          @super_late << planting
        elsif planting.late?
          @late << planting
        elsif planting.harvest_time?
          @harvesting << planting
        else
          @others << planting
        end
      end
    end

    @subject = "Your #{Date.today.strftime('%B %Y')} #{@sitename} progress report"

    # Encrypting
    message = { member_id: @member.id, type: :send_planting_reminder }
    @signed_message = verifier.generate(message)

    mail(to: @member.email, subject: @subject) if @member.send_planting_reminder
  end

  def new_crop_request(member, request)
    @member = member
    @request = request
    mail(to: @member.email, subject: "#{@request.requester.login_name} has requested #{@request.name} as a new crop")
  end

  def crop_request_approved(member, crop)
    @member = member
    @crop = crop
    mail(to: @member.email, subject: "#{crop.name.capitalize} has been approved")
  end

  def crop_request_rejected(member, crop)
    @member = member
    @crop = crop
    mail(to: @member.email, subject: "#{crop.name.capitalize} has been rejected")
  end
end
