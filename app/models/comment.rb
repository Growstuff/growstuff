class Comment < ActiveRecord::Base
  belongs_to :author, class_name: 'Member'
  belongs_to :post

  scope :post_order, -> { reorder("created_at ASC") } # for display on post page

  after_create do
    recipient = post.author.id
    sender    = author.id
    # don't send notifications to yourself
    if recipient != sender
      Notification.create(
        recipient_id: recipient,
        sender_id: sender,
        subject: "#{author} commented on #{post.subject}",
        body: body,
        post_id: post.id
      )
    end
  end
end
