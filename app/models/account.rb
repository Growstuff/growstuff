class Account < ActiveRecord::Base
  attr_accessible :account_type_id, :member_id, :paid_until
  belongs_to :member
  belongs_to :account_type

  validates :member_id, :uniqueness => {
    :message => 'already has account details associated with it'
  }

  before_create do |account|
    unless account.account_type
      account.account_type = AccountType.find_or_create_by_name("Free")
    end
  end

  def paid_until_string
    if account_type.is_permanent_paid
      return "forever"
    elsif account_type.is_paid
      return paid_until.to_s
    end
  end

end
