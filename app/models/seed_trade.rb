class SeedTrade < ActiveRecord::Base
  belongs_to :seed
  belongs_to :requester, class_name: 'Member'

  default_scope { order(created_at: :desc) }

  # List seed trades both when member is requester and seed owner
  scope :by_member,
                 ->(member) { includes(:seed).where(
                 'seeds.owner_id = ? OR requester_id = ?',
                 member.id, member.id).references(:seeds) }

  scope :not_replied,
                 ->{where("accepted_date IS NULL AND declined_date IS NULL")}

  validates :message, presence: true, allow_blank: false
  validates :address, presence: true, allow_blank: false

  def replied?
    self.accepted? || self.declined?
  end

  def status
    return "Received"  if self.received?
    return "Sent"      if self.sent?
    return "Accepted"  if self.accepted?
    return "Declined"  if self.declined?
    "Requested"
  end

  def accepted?
    accepted_date
  end

  def declined?
    declined_date
  end

  def sent?
    sent_date
  end

  def received?
    received_date
  end
end
