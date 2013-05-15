require 'spec_helper'

describe ApplicationHelper do
  it "formats prices" do
    price_in_dollars(999).should eq '9.99'
    price_with_currency(999).should eq '9.99 AUD'
  end
end
