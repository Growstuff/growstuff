require 'spec_helper'

describe ApplicationHelper do
  it "formats prices" do
    format_price(999).should eq '9.99 AUD'
  end
end
