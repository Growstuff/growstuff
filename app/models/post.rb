class Post < ActiveRecord::Base
  extend FriendlyId
  friendly_id :user_date_subject, use: :slugged
  attr_accessible :body, :subject, :user_id
  belongs_to :user
  default_scope order("created_at desc")

  def user_date_subject
    # slugs are created before created_at is set
    time = created_at || Time.now
    "#{user.username} #{time.strftime("%Y%m%d")} #{subject}"
  end
end
