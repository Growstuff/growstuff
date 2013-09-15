module NotificationsHelper
  def reply_link(notification)
    if notification.post
      # comment on the post in question
      new_comment_url(:post_id => notification.post.id)
    else
      # by default, reply link sends a PM in return
      new_notification_url(
        :recipient_id => notification.sender.id,
        :in_reply_to_id => notification.id,
        :subject => notification.subject =~ /^Re: / ?
          notification.subject :
          "Re: " + notification.subject
      )
    end
  end
end
