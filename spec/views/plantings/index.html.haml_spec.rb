require 'spec_helper'

describe "plantings/index" do
  before(:each) do
    assign(:plantings, [
      stub_model(Planting,
        :garden_id => 1,
        :crop_id => 2,
        :quantity => 3,
        :description => "MyText"
      ),
      stub_model(Planting,
        :garden_id => 1,
        :crop_id => 2,
        :quantity => 3,
        :description => "MyText"
      )
    ])
  end

  it "renders a list of plantings" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
