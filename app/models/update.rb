class Update < ActiveRecord::Base
  extend FriendlyId
  friendly_id :subject, use: :slugged
  attr_accessible :body, :subject, :user_id
  belongs_to :user
  default_scope order("created_at desc")
end
