class Notifier < ActionMailer::Base
  include NotificationsHelper
  default from: "Growstuff <noreply@growstuff.org>"

  def notify(notification)
    @notification = notification
    @reply_link = reply_link(@notification)

    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end

  def planting_reminder(member)
    @member = member

    @plantings = @member.plantings.first(5)
    @harvests = @member.harvests.first(5)

    if @member.send_planting_reminder
      mail(:to => @member.email,
          :subject => "What have you planted lately?")
    end
  end

  def new_crop_request(member, request)
    @member, @request = member, request
    mail(:to => @member.email, :subject => "New crop request")    
  end

  def crop_request_approved(member, crop)
    @member, @crop = member, crop
    mail(:to => @member.email, :subject => "#{crop.name.capitalize} has been approved")
  end

end
