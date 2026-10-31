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
  belongs_to :card_photo, class_name: 'Photo', optional: true, inverse_of: false
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :crop_posts, dependent: :delete_all
  has_many :crops, through: :crop_posts
  has_many :notifications, as: :notifiable, dependent: :destroy

  #
  # Triggers
  before_save :set_published_at
  after_save :update_crop_posts_association
  after_save :send_notification, if: -> { saved_change_to_published_at? && published? }
  after_save :update_author_spam_score

  # Drafts have no published_at and are left out of every list and lookup, so
  # they cannot leak. The author's own pages ask for them with `with_drafts`.
  default_scope { joins(:author).merge(Member.kept).where.not(published_at: nil) } # Kept: ensures the owner still exists
  scope :with_drafts, -> { unscope(where: :published_at) }

  # Not stored. `true` saves a draft, `false` publishes one, and nil (the
  # default) publishes a new post and leaves an existing one as it is.
  attribute :draft, :boolean

  #
  # Validations
  # A draft can be saved blank (a photo needs a saved post to go on); a post
  # being published needs both.
  validates :subject, presence: true, if: :publishing?
  validates :subject, length: { maximum: 255 }
  validates :body, presence: true, if: :publishing?
  validate :card_photo_is_in_post, if: :card_photo_id?

  WORDS_PER_MINUTE = 200

  # The card photo the author chose, else the most liked photo on the post.
  def default_photo
    card_photo || most_liked_photo
  end

  def published?
    published_at.present?
  end

  def draft?
    !published?
  end

  def read_time_minutes
    [(body.to_s.split.size.to_f / WORDS_PER_MINUTE).ceil, 1].max
  end

  def more_from_author(limit = 3)
    author.posts.where.not(id:).order(created_at: :desc).limit(limit)
  end

  # A draft's address follows its title until it is published.
  def should_generate_new_friendly_id?
    slug.blank? || (draft? && subject_changed?)
  end

  def author_date_subject
    return unless author

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
    left_joins(:comments)
      .select('posts.*, COALESCE(MAX(comments.created_at), posts.created_at) AS last_activity_at')
      .group('posts.id')
      .order(Arel.sql('last_activity_at DESC'))
  end

  def owner_id
    author_id
  end

  def to_s
    subject
  end

  private

  # Being published by this save: a published post stays so, a new one is
  # unless it is a draft, and a draft is when asked with `draft: false`.
  def publishing?
    return true if published?
    return false if draft == true

    new_record? || draft == false
  end

  def set_published_at
    self.published_at = Time.current if !published? && publishing?
  end

  def card_photo_is_in_post
    errors.add(:card_photo, :invalid) unless photos.exists?(card_photo_id)
  end

  def update_crop_posts_association
    crops.clear
    # look for crops mentioned in the post. eg. [tomato](crop)
    body.scan(Haml::Filters::GrowstuffMarkdown::CROP_REGEX) do |_m|
      crop_name = Regexp.last_match(1)
      crop = Crop.case_insensitive_name(crop_name).first
      # create association
      crops << crop if crop && crops.exclude?(crop)
    end
  end

  def update_author_spam_score
    author&.update_spam_score!
  end

  def send_notification
    recipients = []
    sender = author.id
    body.scan(Haml::Filters::GrowstuffMarkdown::MEMBER_REGEX) do |_m|
      # find member case-insensitively and add to list of recipients
      member = Member.case_insensitive_login_name(Regexp.last_match(1)).first
      recipients << member if member && recipients.exclude?(member)
    end
    body.scan(Haml::Filters::GrowstuffMarkdown::MEMBER_AT_REGEX) do |_m|
      # find member case-insensitively and add to list of recipients
      member = Member.case_insensitive_login_name(Regexp.last_match(1)[1..]).first
      recipients << member if member && recipients.exclude?(member)
    end
    # don't send notifications to yourself
    recipients.map(&:id).each do |recipient_id|
      next unless recipient_id != sender

      Notification.create(
        recipient_id:,
        sender_id:    sender,
        notifiable:   self,
        subject:      "#{author} mentioned you in their post #{subject}",
        body:
      )
    end
  end
end
