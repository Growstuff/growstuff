class SeedTrade < ActiveRecord::Base
  belongs_to :seed
  belongs_to :requester, class_name: 'Member'

  default_scope { order("seed_trades.created_at desc") }

  # List seed trades both when member is requester and seed owner
  scope :by_member,
                 ->(member) { includes(:seed).where(
                 'seeds.owner_id = ? or requester_id = ?',
                 member.id, member.id).references(:seeds) }

  validates :message, presence: true, allow_blank: false
  validates :address, presence: true, allow_blank: false

  def replyed?
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
