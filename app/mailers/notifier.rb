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

    @plantings = @member.plantings.last(5)
    @harvests = @member.harvests.last(5)

    if @member.send_planting_reminder
      mail(:to => @member.email,
          :subject => "What have you planted lately?")
    end
  end

end
