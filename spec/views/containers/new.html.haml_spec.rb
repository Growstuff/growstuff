require 'rails_helper'

describe "containers/new" do
  before(:each) do
    @owner = FactoryBot.create(:admin_member)
    sign_in @owner
    controller.stub(:current_user) { @owner }
    @container = assign(:container, FactoryBot.create(:container))
    render
  end

  it "renders new container form" do
    assert_select "form", action: garden_types_path, method: "post" do
      assert_select "input#container_description", name: "container[description]"
    end
  end
end
