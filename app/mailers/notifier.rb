class Notifier < ActionMailer::Base
  default from: "#{site_name} <#{email_from_address}>"

  def notify(notification)
    @notification = notification
    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end
end
