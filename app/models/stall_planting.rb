# frozen_string_literal: true

# A seedling on a member's stall. First it may only be on offer, with nobody to give it to yet; then it is given away, and
# says who it went to: a member picked from Growstuff, or a name the giver uses for someone who isn't one, with the email
# address or Fediverse or Bluesky handle they sign in with, if the giver knows it. Whoever it was given to, or signs in
# with that address or handle, can accept it into one of their gardens, and it carries on there. The giver keeps this
# record, as the stall remembering it was given.
#
# The planting's own short code is not secret, so it is no proof of who has the seedling: only signing in as the
# recipient is.
class StallPlanting < ApplicationRecord
  KINDS = %w(email mastodon bluesky).freeze
  MASTODON_FORMAT = /\A@[a-z0-9_.-]+@[a-z0-9-]+(\.[a-z0-9-]+)+\z/
  BLUESKY_DEFAULT_DOMAIN = Atproto::Identity::DEFAULT_DOMAIN

  belongs_to :stall
  belongs_to :planting
  belongs_to :accepted_by, class_name: 'Member', optional: true
  belongs_to :recipient_member, class_name: 'Member', optional: true
  # A friend asking for it while it is on offer.
  has_one :claim, dependent: :destroy

  enum :recipient_kind, KINDS.index_with(&:itself), validate: { allow_nil: true }

  normalizes :recipient, with: ->(value) { value.to_s.strip.downcase }

  before_validation :normalize_handle
  validates :recipient_name, length: { maximum: 100 }
  validate :recipient_is_known, if: :given?
  validates :recipient_kind, presence: true, if: -> { recipient.present? }
  validates :recipient, presence: true, if: -> { recipient_kind.present? }
  validates :planting_id, uniqueness: { conditions: -> { unaccepted } }, unless: :accepted?
  validate :recipient_is_well_formed, if: -> { recipient.present? }
  validate :planting_is_the_stall_owners, on: :create
  validate :planting_is_giveable, if: -> { new_record? || will_save_change_to_given_away_at? }
  # It stops being an active planting of the giver's the moment it is given.
  after_save :take_planting_off_its_owner, if: -> { saved_change_to_given_away_at? && given? }

  scope :unaccepted, -> { where(accepted_at: nil) }
  # On the stall with nobody to give it to yet, or given to someone.
  scope :offered, -> { where(given_away_at: nil) }
  scope :given, -> { where.not(given_away_at: nil) }
  scope :newest_first, -> { order(given_away_at: :desc, id: :desc) }

  # What is waiting for a member: given to them as a member, or to an address or handle that they have signed in with, and
  # not accepted into a garden yet. An email counts as theirs once confirmed, which is all `email` ever holds; a handle counts once they
  # have signed in with it.
  scope :waiting_for, lambda { |member|
    given.unaccepted.where(recipient_member_id: member.id)
      .or(given.unaccepted.where(recipient_kind: 'email', recipient: member.email.to_s.downcase.presence || '-'))
      .or(given.unaccepted.where(recipient_kind: 'mastodon', recipient: member.handles_for('mastodon')))
      .or(given.unaccepted.where(recipient_kind: 'bluesky', recipient: member.handles_for('bluesky')))
  }

  def accepted?
    accepted_at.present?
  end

  def given?
    given_away_at.present?
  end

  # On the stall with nobody to give it to yet.
  def offered?
    !given?
  end

  # Who it went to, as the giver put it: the member's name, or the name they used.
  def recipient_label
    recipient_member&.to_s.presence || recipient_name
  end

  def waiting_for?(member)
    !accepted? && self.class.waiting_for(member).exists?(id)
  end

  # The member takes the seedling into one of their gardens. The giver's planting stays as it was, marked as given away, and
  # a new planting is made for the member, which knows where it came from. Returns the new planting, or false and says why in
  # the errors.
  def accept(member, garden)
    errors.add(:base, :not_for_you) unless waiting_for?(member)
    errors.add(:base, :not_your_garden) unless garden&.owner_id == member.id
    return false if errors.any?

    transaction do
      received = planting.pass_on_to(member, garden)
      update!(accepted_by: member, accepted_at: Time.current)
      claim&.finish!
      received
    end
  end

  private

  def normalize_handle
    return if recipient.blank? || recipient_kind.blank?

    self.recipient = case recipient_kind
                     when 'mastodon' then "@#{recipient.delete_prefix('@')}"
                     when 'bluesky' then bluesky_handle
                     else recipient
                     end
  end

  # alice, @alice.bsky.social and alice.bsky.social are the same handle.
  def bluesky_handle
    handle = recipient.delete_prefix('@')
    handle.include?('.') ? handle : "#{handle}.#{BLUESKY_DEFAULT_DOMAIN}"
  end

  # Given to a member, or to someone the giver can name.
  def recipient_is_known
    errors.add(:base, :recipient_unknown) if recipient_member.blank? && recipient_name.blank?
  end

  def recipient_is_well_formed
    valid = case recipient_kind
            when 'email' then URI::MailTo::EMAIL_REGEXP.match?(recipient)
            when 'mastodon' then MASTODON_FORMAT.match?(recipient)
            when 'bluesky' then Atproto::Identity::HANDLE_FORMAT.match?(recipient)
            else true # reported by the kind's own validation
            end
    errors.add(:recipient, :invalid) unless valid
  end

  def planting_is_the_stall_owners
    errors.add(:planting, :invalid) unless planting && stall && planting.owner_id == stall.member_id
  end

  def take_planting_off_its_owner
    planting.update_columns(given_away_at:) # rubocop:disable Rails/SkipsModelValidations
  end

  def planting_is_giveable
    errors.add(:planting, :not_giveable) if planting && !planting.giveable?
  end
end
