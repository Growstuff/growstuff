class Update < ActiveRecord::Base
  attr_accessible :body, :subject, :user_id
  belongs_to :user
  default_scope order("created_at desc")
end
