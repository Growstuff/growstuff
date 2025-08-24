# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true
  # validates :body, presence: true

  scope :post_order, -> { order(created_at: :asc) } # for display on post page

  after_create do
    recipient = commentable.author.id
    sender    = author.id
    # don't send notifications to yourself
    if recipient != sender
      Notification.create(
        recipient_id:        recipient,
        sender_id:           sender,
        subject:             "#{author} commented on #{commentable.subject}",
        body:,
        commentable_id:      commentable.id,
        commentable_id_type: commentable.class.name
      )
    end
  end

  def to_s
    if commentable.is_a?(Post)
      "#{author.login_name} commented on #{commentable.subject}"
    elsif commentable.is_a?(Photo)
      "#{author.login_name} commented on #{commentable.title}"
    else
      "#{author.login_name} commented"
    end
  end
end
