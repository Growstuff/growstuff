# frozen_string_literal: true

require 'rails_helper'

describe "admin/roles/edit" do
  before do
    @role = assign(:role, stub_model(Role,
                                     name:        "MyString",
                                     description: "MyText"))
  end

  it "renders the edit role form" do
    render

    assert_select "form", action: admin_roles_path(@role), method: "post" do
      assert_select "input#role_name", name: "role[name]"
      assert_select "textarea#role_description", name: "role[description]"
    end
  end
end
