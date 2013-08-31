require 'spec_helper'

describe "places/index" do
  before(:each) do
    render
  end

  it "shows a map" do
    assert_select "div#map"
  end
end
