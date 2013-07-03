module ApplicationHelper

  def price_in_dollars(price)
    return sprintf('%.2f', price / 100.0)
  end

  # 999 cents becomes 9.99 AUD -- for products/orders/etc
  def price_with_currency(price)
    return sprintf('%.2f %s', price / 100.0,
        Growstuff::Application.config.currency)
  end

  def parse_date(str)
    str ||= '' # Date.parse barfs on nil
    return str == '' ? nil : Date.parse(str)
  end

  def forex_link()
    return link_to "See exchange rates",
      "http://www.xe.com/currency/aud-australian-dollar?c=CAD",        
      :target => "_blank"
  end 
end

