# frozen_string_literal: true

# Someone a member does not want suggested to them as a person to follow.
class MemberDismissal < ApplicationRecord
  belongs_to :member
  belongs_to :dismissed, class_name: 'Member'

  validates :dismissed_id, uniqueness: { scope: :member_id }
end
