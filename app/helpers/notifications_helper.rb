module NotificationsHelper
  def reply_link(notification)
    if notification.post
      # comment on the post in question
      new_comment_url(post_id: notification.post.id)
    else
      # by default, reply link sends a PM in return
      reply_notification_url(notification)
    end
  end
end
