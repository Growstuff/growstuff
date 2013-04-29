class Notifier < ActionMailer::Base
  default from: "Growstuff <noreply@growstuff.org>"

  def notify(notification)
    @notification = notification

    # by default, reply link sends a PM in return
    @reply_link = new_notification_url(
      :recipient_id => @notification.sender.id,
      :subject => @notification.subject =~ /^Re: / ?
        @notification.subject :
        "Re: " + @notification.subject
    )

    if @notification.post
      # comment on the post in question
      @reply_link = new_comment_url(:post_id => @notification.post.id)
    end

    mail(:to => @notification.recipient.email,
         :subject => @notification.subject)
  end
end
