class Post < ActiveRecord::Base
  extend FriendlyId
  friendly_id :author_date_subject, use: :slugged
  attr_accessible :body, :subject, :author_id
  belongs_to :author, :class_name => 'Member'
  belongs_to :forum
  has_many :comments, :dependent => :destroy
  default_scope order("created_at desc")

  def author_date_subject
    # slugs are created before created_at is set
    time = created_at || Time.now
    "#{author.login_name} #{time.strftime("%Y%m%d")} #{subject}"
  end
end
