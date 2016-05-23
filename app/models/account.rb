class Account < ActiveRecord::Base
  belongs_to :member
  belongs_to :account_type

  validates :member_id, uniqueness: {
    message: 'already has account details associated with it'
  }

  before_create do |account|
    unless account.account_type
      account.account_type = AccountType.find_or_create_by(name: 
        Growstuff::Application.config.default_account_type
      )
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
