require 'spec_helper'

describe "gardens/index" do
  before(:each) do
    assign(:gardens, [
      stub_model(Garden,
        :name => "Name",
        :user_id => "",
        :slug => "Slug"
      ),
      stub_model(Garden,
        :name => "Name",
        :user_id => "",
        :slug => "Slug"
      )
    ])
  end

  it "renders a list of gardens" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
    assert_select "tr>td", :text => "Slug".to_s, :count => 2
  end
end
