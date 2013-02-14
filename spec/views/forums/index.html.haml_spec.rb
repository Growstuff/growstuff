require 'spec_helper'

describe "forums/index" do
  before(:each) do
    @forum1 = FactoryGirl.create(:forum)
    assign(:forums, [ @forum1, @forum1 ])
    render
  end

  it "renders a list of forums" do
    assert_select "h2", :text => @forum1.name, :count => 2
  end

  it "parses markdown description into html" do
    assert_select "em", "Everything"
  end
end
