class Post < ActiveRecord::Base
  extend FriendlyId
  friendly_id :member_date_subject, use: :slugged
  attr_accessible :body, :subject, :member_id
  belongs_to :member
  default_scope order("created_at desc")

  def member_date_subject
    # slugs are created before created_at is set
    time = created_at || Time.now
    "#{member.username} #{time.strftime("%Y%m%d")} #{subject}"
  end
end
