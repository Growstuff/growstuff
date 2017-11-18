require 'rails_helper'

describe RolesController do
  def valid_attributes
    { "name" => "MyString" }
  end

  login_member(:admin_member)

  describe "GET index" do
    it "assigns all roles as @roles" do
      role = Role.create! valid_attributes
      get :index, {}
      # note that admin role exists because of login_admin_member
      assigns(:roles).should eq([Role.find_by(name: 'admin'), role])
    end
  end
end
