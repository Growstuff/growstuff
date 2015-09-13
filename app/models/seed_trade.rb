class SeedTrade < ActiveRecord::Base
  belongs_to :seed
  belongs_to :requester, class_name: 'Member'

  default_scope { order("created_at desc") }
  scope :by_member, ->(member) { where(requester: member) }

  validates :message, presence: true
  validates :address, presence: true

  def replyed?
    self.accepted_date || self.declined_date
  end
end
