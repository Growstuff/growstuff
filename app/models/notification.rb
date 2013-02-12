class Notification < ActiveRecord::Base
  attr_accessible :body, :from_id, :notification_type, :post_id, :read, :subject, :to_id
end
