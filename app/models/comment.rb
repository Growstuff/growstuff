# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: :comments
  belongs_to :commentable, polymorphic: true, counter_cache: true
  # validates :body, presence: true
  validate :author_is_not_blocked

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
        notifiable:   commentable
      )
    end
  end

  def to_s
    "#{author.login_name} commented on #{commentable.subject}"
  end

  private

  def author_is_not_blocked
    return unless author

    return unless commentable.author.already_blocking?(author)

    errors.add(:base, "You cannot comment on a post of a member who has blocked you.")
  end
end
