class Notifier < ActionMailer::Base
  default from: "Growstuff <noreply@growstuff.org>"

  def notify(notification)
    @notification = notification
    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end
end
