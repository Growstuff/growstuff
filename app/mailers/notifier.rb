class Notifier < ActionMailer::Base
  include NotificationsHelper
  default from: "Growstuff <noreply@growstuff.org>"

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

    mail(to: @notification.recipient.email,
         subject: @notification.subject)
  end

  def planting_reminder(member)
    @member = member

    @plantings = @member.plantings.first(5)
    @harvests = @member.harvests.first(5)

    # Encrypting
    message = { member_id: @member.id, type: :send_planting_reminder }
    @signed_message = verifier.generate(message)

    mail(to: @member.email, subject: "What have you planted lately?") if @member.send_planting_reminder
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
