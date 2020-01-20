# frozen_string_literal: true

require 'rails_helper'

describe "admin/roles/new" do
  before do
    assign(:role, stub_model(Role,
                             name:        "MyString",
                             description: "MyText").as_new_record)
  end

  it "renders new role form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", action: admin_roles_path, method: "post" do
      assert_select "input#role_name", name: "role[name]"
      assert_select "textarea#role_description", name: "role[description]"
    end
  end
end
