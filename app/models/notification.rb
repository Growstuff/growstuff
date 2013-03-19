class Notification < ActiveRecord::Base
  attr_accessible :sender_id, :recipient_id,
    :subject, :body, :post_id, :read

  belongs_to :sender, :class_name => 'Member'
  belongs_to :recipient, :class_name => 'Member'
  belongs_to :post

  default_scope order('created_at DESC')
  scope :unread, where(:read => false)

  def self.unread_count
    self.unread.count
  end

end
