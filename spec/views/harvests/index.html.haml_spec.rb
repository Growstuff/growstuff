require 'spec_helper'

describe "harvests/index" do
  before(:each) do
    assign(:harvests, [
      stub_model(Harvest,
        :crop_id => 1,
        :owner_id => 2,
        :quantity => "9.99",
        :units => "Units",
        :notes => "MyText"
      ),
      stub_model(Harvest,
        :crop_id => 1,
        :owner_id => 2,
        :quantity => "9.99",
        :units => "Units",
        :notes => "MyText"
      )
    ])
  end

  it "renders a list of harvests" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "9.99".to_s, :count => 2
    assert_select "tr>td", :text => "Units".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
