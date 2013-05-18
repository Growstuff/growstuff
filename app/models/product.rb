class Product < ActiveRecord::Base
  attr_accessible :description, :min_price, :name,
  :account_type_id, :paid_months

  has_and_belongs_to_many :orders
  belongs_to :account_type

  validates :paid_months, :numericality => { :only_integer => true,
    :allow_nil => true }

  def to_s
    name
  end

  # when purchasing a product that gives you a paid account, this method
  # does all the messing around to actually make sure the account is
  # updated correctly -- account type, paid until, etc.  Usually this is
  # called by order.update_account, which loops through all order items
  # and does this for each one.
  def update_account(member)
    member.account.account_type = account_type
    if paid_months
      start_date = member.account.paid_until || Time.zone.now
      member.account.paid_until = start_date + paid_months.months
    end
    member.account.save
  end

end
