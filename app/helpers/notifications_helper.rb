# frozen_string_literal: true

module NotificationsHelper
  def reply_link(notification)
    return "" unless notification.sender

    # Mailboxer provides the conversation.
    # We want to link to the conversation where the message belongs.
    # If it's a new message, we might want to link to new_message_path(recipient_id: notification.sender_id)
    # But Notification model seems to be tied to existing messages.

    if notification.notifiable_type == "Post"
      post_url(notification.notifiable)
    elsif notification.sender
      # Link to the message/conversation
      # Based on routes.rb: resources :conversations
      # We need to find the conversation between sender and recipient
      conversation = notification.recipient.mailbox.conversations.joins(:participants).where(mailboxer_notifications: { sender_id: notification.sender_id }).first
      if conversation
        conversation_url(conversation)
      else
        new_message_url(recipient_id: notification.sender.id)
      end
    else
      root_url
    end
  end
end
