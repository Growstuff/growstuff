# frozen_string_literal: true

require 'rails_helper'

describe AuthenticationsController do
  before do
    @member = FactoryBot.create(:member)
    sign_in @member
    controller.stub(:current_member) { @member }
    @auth = FactoryBot.create(:authentication, member: @member)
    request.env['omniauth.auth'] = {
      'provider'    => 'foo',
      'uid'         => 'bar',
      'info'        => { 'nickname' => 'blah' },
      'credentials' => { 'token' => 'blah', 'secret' => 'blah' }
    }
  end
end
