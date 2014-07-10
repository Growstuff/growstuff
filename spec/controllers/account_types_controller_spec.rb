require 'spec_helper'

describe AccountTypesController do

  # This automatically creates a "Free" account type
  login_member(:admin_member)

  def valid_attributes
    { "name" => "MyString" }
  end

end
