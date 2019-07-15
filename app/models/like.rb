class Like < ApplicationRecord
  belongs_to :member
  belongs_to :likeable, polymorphic: true
  validates :member, :likeable, presence: true
  validates :member, uniqueness: { scope: :likeable }

  after_create do
    Notification.create(
      recipient: likeable.owner,
      sender:    member,
      subject:   "#{member.login_name} liked your #{likeable_type}",
      item:      self,
      should_send_email: false
    )
  end
end
