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
end
