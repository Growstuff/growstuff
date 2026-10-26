# frozen_string_literal: true

require 'rails_helper'

describe AdminController do
  login_member(:admin_member)

  describe "GET admin" do
    before { get :index }

    it { expect(response).to be_successful }
  end
end
