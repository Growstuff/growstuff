# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true

  scope :post_order, -> { order(created_at: :asc) } # for display on post page

  after_create do
    recipient = if commentable.respond_to?(:author)
                  commentable.author.id
                elsif commentable.respond_to?(:owner)
                  commentable.owner.id
                end
    sender    = author.id
    # don't send notifications to yourself
    if recipient && recipient != sender
      Notification.create(
        recipient_id: recipient,
        sender_id:    sender,
        subject:      "#{author} commented on your #{commentable.class.name.downcase}",
        body:,
        commentable_id: commentable.id,
        commentable_type: commentable.class.name
      )
    end
  end

  def to_s
    "#{author.login_name} commented on #{commentable.class.name.downcase} ##{commentable.id}"
  end
end
