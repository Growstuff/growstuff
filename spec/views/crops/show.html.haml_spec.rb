require 'spec_helper'

describe "crops/show" do
  before(:each) do
    @crop = assign(:crop, stub_model(Crop,
      :system_name => "System Name",
      :en_wikipedia_url => "En Wikipedia Url"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/En Wikipedia Url/)
  end
end
