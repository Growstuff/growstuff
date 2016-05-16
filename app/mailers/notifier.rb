class Notifier < ActionMailer::Base
  include NotificationsHelper
  default from: "Growstuff <noreply@growstuff.org>"

  def verifier()
    if ENV['RAILS_SECRET_TOKEN']
      return ActiveSupport::MessageVerifier.new(ENV['RAILS_SECRET_TOKEN'])
    else
      raise "RAILS_SECRET_TOKEN environment variable not set - have you created config/application.yml?"
    end
  end

  def notify(notification)
    @notification = notification
    @reply_link = reply_link(@notification)

    # Encrypting 
    @signed_message = verifier.generate ({ member_id: @notification.recipient.id, type: :send_notification_email })

    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end

  def planting_reminder(member)
    @member = member

    @plantings = @member.plantings.first(5)
    @harvests = @member.harvests.first(5)

    # Encrypting 
    @signed_message = verifier.generate ({ member_id: @member.id, type: :send_planting_reminder })

    if @member.send_planting_reminder
      mail(:to => @member.email,
          :subject => "What have you planted lately?")
    end
  end

  def new_crop_request(member, request)
    @member, @request = member, request
    mail(:to => @member.email, :subject => "#{@request.requester.login_name} has requested #{@request.name} as a new crop")    
  end

  def crop_request_approved(member, crop)
    @member, @crop = member, crop
    mail(:to => @member.email, :subject => "#{crop.name.capitalize} has been approved")
  end

  def crop_request_rejected(member, crop)
    @member, @crop = member, crop
    mail(:to => @member.email, :subject => "#{crop.name.capitalize} has been rejected")
  end

end
