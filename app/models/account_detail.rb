class AccountDetail < ActiveRecord::Base
  attr_accessible :account_type_id, :member_id, :paid_until
  belongs_to :member
  belongs_to :account_type
end
