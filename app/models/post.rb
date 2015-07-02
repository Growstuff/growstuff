class Post < ActiveRecord::Base
  extend FriendlyId
  include Likeable
  friendly_id :author_date_subject, use: [:slugged, :finders]
  belongs_to :author, :class_name => 'Member'
  belongs_to :forum
  has_many :comments, :dependent => :destroy
  has_and_belongs_to_many :crops
  before_destroy {|post| post.crops.clear}
  after_save :update_crops_posts_association
  # also has_many notifications, but kinda meaningless to get at them
  # from this direction, so we won't set up an association for now.

  default_scope { order("created_at desc") }

  validates :subject,
    :format => {
      :with => /\S/
    }

  def author_date_subject
    # slugs are created before created_at is set
    time = created_at || Time.zone.now
    "#{author.login_name} #{time.strftime("%Y%m%d")} #{subject}"
  end

  def comment_count
    self.comments.count
  end

  # return the timestamp of the most recent activity on this post
  # i.e. the time of the most recent comment, or of the post itself if
  # there are no comments.
  def recent_activity
    self.comments.present? ? self.comments.reorder('created_at DESC').first.created_at : self.created_at
  end

  # return posts sorted by recent activity
  def Post.recently_active
    Post.all.sort do |a,b|
      b.recent_activity <=> a.recent_activity
    end
  end

  private
    def update_crops_posts_association
      self.crops.destroy_all
      # look for crops mentioned in the post. eg. [tomato](crop)
      self.body.scan(Haml::Filters::GrowstuffMarkdown::CROP_REGEX) do |m|
        # find crop case-insensitively
        crop = Crop.where('lower(name) = ?', $1.downcase).first
        # create association
        self.crops << crop if crop and not self.crops.include?(crop) 
      end
    end
end
