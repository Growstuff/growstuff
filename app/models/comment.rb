class Comment < ActiveRecord::Base
  attr_accessible :author_id, :body, :post_id
  belongs_to :author, :class_name => 'Member'
  belongs_to :post

  after_create do
    recipient = self.post.author.id
    sender    = self.author.id
    # don't send notifications to yourself
    if recipient != sender
      Notification.create(
        :recipient_id => recipient,
        :sender_id => sender,
        :subject => "#{self.author} commented on #{self.post.subject}",
        :body => self.body,
        :post_id => self.post.id
      )
    end
  end

end
