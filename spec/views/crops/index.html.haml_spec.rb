require 'spec_helper'

describe "crops/index" do
  before(:each) do
    assign(:crops, [
      stub_model(Crop,
        :system_name => "System Name",
        :en_wikipedia_url => "En Wikipedia Url"
      ),
      stub_model(Crop,
        :system_name => "System Name",
        :en_wikipedia_url => "En Wikipedia Url"
      )
    ])
  end

  it "renders a list of crops" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "System Name".to_s, :count => 2
    assert_select "tr>td", :text => "En Wikipedia Url".to_s, :count => 2
  end
end
