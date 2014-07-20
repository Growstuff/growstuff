class Notifier < ActionMailer::Base
  include NotificationsHelper
  default from: "Growstuff <noreply@growstuff.org>"

  def notify(notification)
    @notification = notification
    @reply_link = reply_link(@notification)

    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end

  def regular_email(member)
    @member = member

    @plantings = member.plantings.reorder.last(5)
    @harvests = member.harvests.reorder.last(5)

    mail(:to => @member.email,
         :subject => "This is your regular contact email")
  end

end
