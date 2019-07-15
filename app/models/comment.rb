class Comment < ApplicationRecord
  belongs_to :author, -> { with_deleted }, class_name: 'Member', inverse_of: :comments
  belongs_to :post
  has_one :notification, as: :item

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
        item:         self,
        should_send_email: true
      )
    end
  end

  def to_s
    "#{author.login_name} commented on #{post.subject}"
  end
end
