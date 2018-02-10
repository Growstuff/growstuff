require 'rails_helper'

describe "roles/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    assign(:roles, [
             stub_model(Role,
               name: "Name",
               description: "MyText"),
             stub_model(Role,
               name: "Name",
               description: "MyText")
           ])
  end

  it "renders a list of roles" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
  end
end
