class AccountDetail < ActiveRecord::Base
  attr_accessible :account_type, :member_id, :paid_until
  belongs_to :member
end
