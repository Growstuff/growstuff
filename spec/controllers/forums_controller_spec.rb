# frozen_string_literal: true

require 'rails_helper'

describe ForumsController do
  login_member(:admin_member)

  def valid_attributes
    {
      "name"        => "MyString",
      "description" => "Something",
      "owner_id"    => 1
    }
  end

  def valid_session
    {}
  end
end
