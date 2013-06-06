class Account < ActiveRecord::Base
  attr_accessible :account_type_id, :member_id, :paid_until
  belongs_to :member
  belongs_to :account_type

  validates :member_id, :uniqueness => {
    :message => 'already has account details associated with it'
  }

  def account_type_string
    if account_type
      return account_type.name
    else
      return "Free"
    end
  end

  def paid_until_string
    if account_type
      if account_type.is_permanent_paid
        return "forever"
      elsif account_type.is_paid
        return paid_until.to_s
      end
    end
    return nil
  end

end
