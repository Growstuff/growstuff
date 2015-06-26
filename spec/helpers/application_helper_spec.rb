require 'rails_helper'

describe ApplicationHelper do
  it "formats prices" do
    price_in_dollars(999).should eq '9.99'
    price_with_currency(999).should eq '9.99 %s' % Growstuff::Application.config.currency
  end

  it "parses dates" do
    parse_date(nil).should eq nil
    parse_date('').should eq nil
    parse_date('2012-05-12').should eq Date.new(2012, 5, 12)
    parse_date('may 12th 2012').should eq Date.new(2012, 5, 12)
  end
end
