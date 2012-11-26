require 'spec_helper'

describe "gardens/show" do
  before(:each) do
    @garden = assign(:garden, stub_model(Garden,
      :name => "Garden Name"
    ))
  end

  # garden name is shown in the header, so it's hard to test from here
  # other garden attributes (eg. slug) aren't rendered on the page

end
