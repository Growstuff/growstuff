# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: :comments
  belongs_to :post, counter_cache: true

  scope :post_order, -> { reorder("created_at ASC") } # for display on post page

  after_create do
    recipient = post.author.id
    sender    = author.id
    # don't send notifications to yourself
    if recipient != sender
      Notification.create(
        recipient_id: recipient,
        sender_id:    sender,
        subject:      "#{author} commented on #{post.subject}",
        body:         body,
        post_id:      post.id
      )
    end
  end

  def to_s
    "#{author.login_name} commented on #{post.subject}"
  end
end
