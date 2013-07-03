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

  def forex_link(price)
    pid = price_in_dollars(price)
    link = "http://www.wolframalpha.com/input/?i=#{pid}+aud"
    return link_to "See exchange rates",
      link,
      :target => "_blank"
  end 

end

