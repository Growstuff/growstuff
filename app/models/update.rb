class Update < ActiveRecord::Base
  attr_accessible :body, :subject, :user_id
  belongs_to :user
end
