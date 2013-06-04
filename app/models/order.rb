class Order < ActiveRecord::Base
  attr_accessible :member_id, :completed_at
  belongs_to :member

  has_many :order_items, :dependent => :destroy

  default_scope order('created_at DESC')

  # total price of an order
  def total
    order_items.to_a.sum(&:price)
  end

  # return items in the format ActiveMerchant/PayPal want them
  def activemerchant_items
    items = []
    order_items.each do |i|
      items.push({
        :name => i.product.name,
        :quantity => i.quantity,
        :amount => i.price
      })
    end
    return items
  end

  # record the paypal details for reference
  def record_paypal_details(token)
    self.paypal_express_token = token
    details = EXPRESS_GATEWAY.details_for(token)
    self.paypal_express_payer_id = details.payer_id
    self.save
  end

  # when an order is completed, we update the member's account to mark
  # them as paid, or whatever, based on what products they ordered
  def update_account
    order_items.each do |i|
      member.update_account_after_purchase(i.product)
    end
  end

end
