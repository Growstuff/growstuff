require 'spec_helper'

describe "forums/show" do
  before(:each) do
    @forum = assign(:forum, stub_model(Forum,
      :name => "Name",
      :description => "MyText",
      :owner_id => 1
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/MyText/)
    rendered.should match(/1/)
  end
end
