class Update < ActiveRecord::Base
  extend FriendlyId
  friendly_id :subject, use: :slugged
  attr_accessible :body, :subject, :user_id
  belongs_to :user
  default_scope order("created_at desc")

  def to_param
      "#{created_at.year}/#{created_at.month}/#{created_at.day}/#{slug}"
  end
end
