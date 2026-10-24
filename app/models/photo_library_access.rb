# frozen_string_literal: true

# Whether a member may upload photos to the Growstuff photo library. A member
# asks for it; an admin approves or refuses the request, and can revoke it later.
# Linking a photo hosted elsewhere, such as on Flickr, needs none of this.
class PhotoLibraryAccess < ApplicationRecord
  STATUSES = %w(requested approved refused revoked).freeze

  belongs_to :member
  belongs_to :decided_by, class_name: 'Member', optional: true

  validates :member, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :request_message, length: { maximum: 1000 }
  validates :note, length: { maximum: 1000 }

  STATUSES.each do |status|
    scope status, -> { where(status:) }
    define_method(:"#{status}?") { self.status == status }
  end

  # Asks for access again, after a refusal or revocation too. An approved
  # member's access is left as it is.
  def self.request!(member, message = nil)
    access = find_or_initialize_by(member:)
    return access if access.approved?

    access.update!(status: 'requested', request_message: message, decided_by: nil, decided_at: nil, note: nil)
    access
  end

  # After request!, whether this was a new request rather than a repeat of one
  # still waiting or of an approval.
  def newly_requested?
    requested? && (previously_new_record? || saved_change_to_status?)
  end

  def approve!(admin, note = nil)
    decide!('approved', admin, note)
  end

  def refuse!(admin, note = nil)
    decide!('refused', admin, note)
  end

  def revoke!(admin, note = nil)
    decide!('revoked', admin, note)
  end

  private

  def decide!(status, admin, note)
    update!(status:, decided_by: admin, decided_at: Time.zone.now, note:)
  end
end
