module ApplicationHelper

  # 999 cents becomes 9.99 AUD -- for products/orders/etc
  def format_price(price)
    return sprintf('%.2f %s', price / 100.0,
        Growstuff::Application.config.currency)
  end

end

