class SeedTrade < ActiveRecord::Base
  belongs_to :seed
  belongs_to :requester, class_name: 'Member'

  default_scope { order("seed_trades.created_at desc") }
  scope :by_member,
                 ->(member) { includes(:seed).where(
                 'seeds.owner_id = ? or requester_id = ?',
                 member.id, member.id).references(:seeds) }

  validates :message, presence: true
  validates :address, presence: true

  def replyed?
    self.accepted_date || self.declined_date
  end

  def sent?
    sent_date
  end

  def received?
    received_date
  end
end
