class Comment < ActiveRecord::Base
  attr_accessible :author_id, :body, :post_id
  belongs_to :author, :class_name => 'Member'
  belongs_to :post

  after_create {
    Notification.create(
      :to_id => self.post.author.id,
      :from_id => self.author.id,
      :subject => "New comment on #{self.post.subject}",
      :body => self.body,
      :post_id => self.post.id
    )
  }

end
