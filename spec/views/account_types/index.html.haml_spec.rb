require 'spec_helper'

describe "account_types/index" do
  before(:each) do
    @type = FactoryGirl.create(:account_type)
    assign(:account_types, [@type, @type])
  end

  it "renders a list of account_types" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => @type.name.to_s, :count => 2
  end
end
