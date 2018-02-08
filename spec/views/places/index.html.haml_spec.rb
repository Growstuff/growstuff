require 'rails_helper'

describe "places/index" do
  before(:each) do
    render
  end

  it "shows a map" do
    assert_select "div#placesmap"
  end
end
