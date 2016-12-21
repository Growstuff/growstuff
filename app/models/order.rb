class Order < ActiveRecord::Base
  belongs_to :member

  has_many :order_items, dependent: :destroy

  default_scope { order('created_at DESC') }

  validates :referral_code, format: {
    with: /\A[a-zA-Z0-9 ]*\z/,
    message: "may only include letters and numbers"
  }

  before_save :standardize_referral_code

  scope :by_member, ->(member) { where(member: member) }

  # total price of an order
  def total
    sum = 0
    for i in order_items do
      subtotal = i.price * i.quantity
      sum += subtotal
    end
    sum
  end

  # return items in the format ActiveMerchant/PayPal want them
  def activemerchant_items
    items = []
    order_items.each do |i|
      items.push({
                   name: i.product.name,
                   quantity: i.quantity,
                   amount: i.price
                 })
    end
    items
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

  # removes whitespace and forces to uppercase (we're somewhat liberal
  # in what we accept, but we clean it up anyway.)
  def standardize_referral_code
    self.referral_code = referral_code.upcase.gsub /\s/, '' if referral_code
  end

  # search orders (used by admin/orders)
  # usage: Order.search({ :by => 'member', :for => 'Skud' })
  # can search by: member, order_id, paypal_token, paypal_payer_id,
  def Order.search(args = {})
    if args[:for]
      case args[:by]
      when "member"
        member = Member.find_by(login_name: args[:for])
        if member
          return member.orders
        end
      when "order_id"
        order = Order.find_by(id: args[:for])
        if order
          return [order]
        end
      when "paypal_token"
        order = Order.find_by(paypal_express_token: args[:for])
        if order
          return [order]
        end
      when "paypal_payer_id"
        order = Order.find_by(paypal_express_payer_id: args[:for])
        if order
          return [order]
        end
      when "referral_code"
        # coerce to uppercase
        return Order.where(referral_code: args[:for].upcase)
      end
    end
    []
  end
end
