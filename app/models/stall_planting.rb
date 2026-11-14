# frozen_string_literal: true

# A seedling on a member's stall. First it may only be on offer, with nobody to give it to yet; then it is given away, and
# says who it went to: an email address, or a Fediverse or Bluesky handle. They may not be a member yet. Whoever signs in
# with that address or handle can claim it into one of their gardens, and it carries on there. The giver keeps this
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
  belongs_to :claimed_by, class_name: 'Member', optional: true

  enum :recipient_kind, KINDS.index_with(&:itself), validate: { allow_nil: true }

  normalizes :recipient, with: ->(value) { value.to_s.strip.downcase }

  before_validation :normalize_handle
  validates :recipient, :recipient_kind, presence: true, if: :given?
  validates :planting_id, uniqueness: { conditions: -> { unclaimed } }, unless: :claimed?
  validate :recipient_is_well_formed, if: :given?
  validate :planting_is_the_stall_owners, on: :create
  validate :planting_is_giveable, if: -> { new_record? || will_save_change_to_given_away_at? }
  # It stops being an active planting of the giver's the moment it is given.
  after_save :take_planting_off_its_owner, if: -> { saved_change_to_given_away_at? && given? }

  scope :unclaimed, -> { where(claimed_at: nil) }
  # On the stall with nobody to give it to yet, or given to someone.
  scope :offered, -> { where(given_away_at: nil) }
  scope :given, -> { where.not(given_away_at: nil) }
  scope :newest_first, -> { order(given_away_at: :desc, id: :desc) }

  # What is waiting for a member: given to an address or handle that they have signed in with, and not claimed yet. An
  # email counts as theirs once confirmed, which is all `email` ever holds; a handle counts once they have signed in with it.
  scope :waiting_for, lambda { |member|
    unclaimed.where(recipient_kind: 'email', recipient: member.email.to_s.downcase.presence || '-')
      .or(unclaimed.where(recipient_kind: 'mastodon', recipient: member.handles_for('mastodon')))
      .or(unclaimed.where(recipient_kind: 'bluesky', recipient: member.handles_for('bluesky')))
  }

  def claimed?
    claimed_at.present?
  end

  def given?
    given_away_at.present?
  end

  def waiting_for?(member)
    !claimed? && self.class.waiting_for(member).exists?(id)
  end

  # Hands the planting to the member, into one of their gardens, where it carries on as theirs: a fresh short code, as
  # theirs are their own, and where it came from, as a gift from the giver. The giver's own notes on it stay with the giver.
  # Returns whether it was claimed; if not, errors say why.
  def claim(member, garden) # rubocop:disable Naming/PredicateMethod
    errors.add(:base, :not_for_you) unless waiting_for?(member)
    errors.add(:base, :not_your_garden) unless garden&.owner_id == member.id
    return false if errors.any?

    transaction do
      giver = planting.owner
      planting.histories.build(garden: planting.garden, started_on: planting.planted_at || given_away_at.to_date, ended_on: Time.zone.today)
      planting.assign_attributes(owner: member, garden:, given_away_at: nil, short_code: Planting.generate_short_code(member))
      planting.save!
      (planting.seedling || planting.build_seedling).update!(source: 'gift', supplier: giver.to_s, label_text: nil)
      update!(claimed_by: member, claimed_at: Time.current)
    end
    true
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
