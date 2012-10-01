require 'spec_helper'

describe "crops/index" do
  before(:each) do
    assign(:crops, [
      stub_model(Crop,
        :system_name => "Maize",
        :en_wikipedia_url => "http://en.wikipedia.org/wiki/Maize"
      ),
      stub_model(Crop,
        :system_name => "Tomato",
        :en_wikipedia_url => "http://en.wikipedia.org/wiki/Tomato"
      )
    ])
  end

  it "renders a list of crops" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "a", :text => "Maize"
    assert_select "a", :text => "Tomato"
  end
end
