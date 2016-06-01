class Comment < ActiveRecord::Base
  belongs_to :author, class_name: 'Member'
  belongs_to :post

  default_scope { order("created_at DESC") }
  scope :post_order, -> { reorder("created_at ASC") } # for display on post page

  after_create do
    recipient = self.post.author.id
    sender    = self.author.id
    # don't send notifications to yourself
    if recipient != sender
      Notification.create(
        recipient_id: recipient,
        sender_id: sender,
        subject: "#{self.author} commented on #{self.post.subject}",
        body: self.body,
        post_id: self.post.id
      )
    end
  end

end
