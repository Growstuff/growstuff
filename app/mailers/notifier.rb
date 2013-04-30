class Notifier < ActionMailer::Base
  default from: "#{Growstuff::Application.config.site_name} <#{Growstuff::Application.config.email_from_address}>"

  def notify(notification)
    @notification = notification
    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end
end
