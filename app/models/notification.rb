class Notification < ActiveRecord::Base
  attr_accessible :to_id, :from_id,
    :subject, :body, :post_id,
    :notification_type, :read

  belongs_to :sender, :class_name => 'Member', :foreign_key => 'from_id'
  belongs_to :recipient, :class_name => 'Member', :foreign_key => 'to_id'
  belongs_to :post

end
