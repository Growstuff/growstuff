class Trade < ApplicationRecord
  belongs_to :seed
  belongs_to :requested_by, class_name: 'Member', inverse_of: :trades
  has_one :owner, through: :seed
  has_one :crop, through: :seed

  after_create do
    Notification.create(
      recipient: seed.owner,
      sender:    requested_by,
      subject:   "#{requested_by.login_name} requests your #{seed.crop.name} seeds",
      body:      "View your trades on #{ENV['GROWSTUFF_SITE_NAME']} to accept or decline"
    )
  end

  def to_s
    "#{crop} seeds requested by #{requested_by}"
  end
end
