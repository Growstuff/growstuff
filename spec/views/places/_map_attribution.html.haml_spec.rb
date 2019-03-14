# frozen_string_literal: true

require 'rails_helper'

describe "places/_map_attribution.html.haml", type: :view do
  before do
    render
  end

  it "links to OpenStreetMap" do
    assert_select "a", href: "http://openstreetmap.org",
                       text: "OpenStreetMap"
  end

  it "links to the ODbL" do
    assert_select "a", href: "http://www.openstreetmap.org/copyright",
                       text: "ODbL"
  end

  it "links to CloudMade" do
    assert_select "a", href: "http://cloudmade.com", text: "CloudMade"
  end
end
