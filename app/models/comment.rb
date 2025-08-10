# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true

  scope :post_order, -> { order(created_at: :asc) } # for display on post page

  after_create do
    recipient = commentable.author.id
    sender    = author.id
    # don't send notifications to yourself
    if recipient != sender
      Notification.create(
        recipient_id: recipient,
        sender_id:    sender,
        subject:      "#{author} commented on #{commentable.subject}",
        body:,
        post_id:      commentable.id
      )
    end
  end

  def to_s
    "#{author.login_name} commented on #{commentable.subject}"
  end
end
