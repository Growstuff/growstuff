# frozen_string_literal: true

require 'rails_helper'

describe "garden_types/new" do
  before do
    @owner = FactoryBot.create(:admin_member)
    sign_in @owner
    controller.stub(:current_user) { @owner }
    @garden_type = assign(:garden_type, FactoryBot.create(:garden_type))
    render
  end

  it "renders new garden_type form" do
    assert_select "form", action: garden_types_path, method: "post" do
      assert_select "input#garden_type_name", name: "garden_type[name]"
    end
  end
end
