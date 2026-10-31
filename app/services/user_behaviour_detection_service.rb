# frozen_string_literal: true

# Evaluates recent activity of a member for spam behavior and calculates a spam score.
class UserBehaviourDetectionService
  SPAM_KEYWORDS = [
    'sports betting',
    'betting',
    'casino',
    'poker',
    'viagra',
    'cialis',
    'crypto',
    'cryptocurrency',
    'slot machine',
    'free spins',
    'buy cheap'
  ].freeze

  attr_reader :member

  def initialize(member)
    @member = member
  end

  def self.score_for(member)
    new(member).score
  end

  def score
    # Score ranges from 0 to 100, where higher indicates higher likelihood of spam.
    points = 0

    points += unconfirmed_email_penalty
    points += spam_keywords_penalty

    points.clamp(0, 100)
  end

  def reasons
    findings = []
    findings << 'Unconfirmed email' unless email_confirmed?

    keywords = detected_spam_keywords
    findings << "Spam keywords detected: #{keywords.join(', ')}" if keywords.any?

    findings
  end

  def email_confirmed?
    member.confirmed?
  end

  def bio_present?
    member.bio.present?
  end

  def posts_present?
    recent_posts.any?
  end

  def comments_present?
    recent_comments.any?
  end

  def detected_spam_keywords
    all_texts = user_generated_texts.compact.join(' ').downcase
    SPAM_KEYWORDS.select { |kw| all_texts.include?(kw) }
  end

  def spam_keywords_detected?
    detected_spam_keywords.any?
  end

  private

  def unconfirmed_email_penalty
    email_confirmed? ? 0 : 25
  end

  def spam_keywords_penalty
    matches = detected_spam_keywords
    return 0 if matches.empty?

    # Base penalty for having any spam keyword, plus extra per distinct keyword
    [50 + ((matches.size - 1) * 15), 75].min
  end

  def user_generated_texts
    texts = []
    texts << member.bio if bio_present?

    recent_posts.each do |post|
      texts << post.subject
      texts << post.body
    end

    recent_comments.each do |comment|
      texts << comment.body
    end

    texts
  end

  def recent_posts
    @recent_posts ||= member.posts.with_drafts.order(created_at: :desc).limit(20)
  end

  def recent_comments
    @recent_comments ||= member.comments.order(created_at: :desc).limit(20)
  end
end
