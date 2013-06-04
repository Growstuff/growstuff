class Account < ActiveRecord::Base
  attr_accessible :account_type_id, :member_id, :paid_until
  belongs_to :member
  belongs_to :account_type

  validates :member_id, :uniqueness => {
    :message => 'already has account details associated with it'
  }

end
