# frozen_string_literal: true

class Post < ApplicationRecord
  extend FriendlyId
  include Likeable
  friendly_id :author_date_subject, use: %i(slugged finders)
  include PhotoCapable

  #
  # Relationships
  belongs_to :author, class_name: 'Member', inverse_of: :posts
  belongs_to :forum, optional: true
  has_many :comments, dependent: :destroy
  has_many :crop_posts, dependent: :delete_all
  has_many :crops, through: :crop_posts

  #
  # Triggers
  after_save :update_crop_posts_association
  after_create  :send_notification

  default_scope { joins(:author).merge(Member.kept) } # Ensures the owner still exists

  #
  # Validations
  validates :subject, presence: true, length: { maximum: 255 }

  def author_date_subject
    # slugs are created before created_at is set
    time = created_at || Time.zone.now
    "#{author.login_name} #{time.strftime('%Y%m%d')} #{subject}"
  end

  def comment_count
    comments.size
  end

  # return the timestamp of the most recent activity on this post
  # i.e. the time of the most recent comment, or of the post itself if
  # there are no comments.
  def recent_activity
    comments.present? ? comments.order(created_at: :desc).first.created_at : created_at
  end

  # return posts sorted by recent activity
  def self.recently_active
    Post.order(created_at: :desc).sort do |a, b|
      b.recent_activity <=> a.recent_activity
    end
  end

  def owner_id
    author_id
  end

  def to_s
    subject
  end

  def reindex(refresh: false); end

  private

  def update_crop_posts_association
    crops.clear
    # look for crops mentioned in the post. eg. [tomato](crop)
    body.scan(Haml::Filters::GrowstuffMarkdown::CROP_REGEX) do |_m|
      crop_name = Regexp.last_match(1)
      crop = Crop.case_insensitive_name(crop_name).first
      # create association
      crops << crop if crop && !crops.include?(crop)
    end
  end

  def send_notification
    recipients = []
    sender = author.id
    body.scan(Haml::Filters::GrowstuffMarkdown::MEMBER_REGEX) do |_m|
      # find member case-insensitively and add to list of recipients
      member = Member.case_insensitive_login_name(Regexp.last_match(1)).first
      recipients << member if member && !recipients.include?(member)
    end
    body.scan(Haml::Filters::GrowstuffMarkdown::MEMBER_AT_REGEX) do |_m|
      # find member case-insensitively and add to list of recipients
      member = Member.case_insensitive_login_name(Regexp.last_match(1)[1..-1]).first
      recipients << member if member && !recipients.include?(member)
    end
    # don't send notifications to yourself
    recipients.map(&:id).each do |recipient_id|
      next unless recipient_id != sender

      Notification.create(
        recipient_id: recipient_id,
        sender_id:    sender,
        subject:      "#{author} mentioned you in their post #{subject}",
        body:         body
      )
    end
  end
end
