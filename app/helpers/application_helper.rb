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
    currency = Growstuff::Application.config.currency
    link = "http://www.wolframalpha.com/input/?i=#{pid}+#{currency}"
    return link_to "(convert)",
      link,
      :target => "_blank"
  end 

  def cache_key_for(klass)
    count          = klass.count
    max_updated_at = klass.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "#{klass.name.downcase.pluralize}/all-#{count}-#{max_updated_at}"
  end

end

