require 'spec_helper'

describe AuthenticationsController do

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_member) { @member }
    @auth = FactoryGirl.create(:authentication, :member => @member)
    request.env['omniauth.auth'] = {
      'provider' => 'foo',
      'uid' => 'bar',
      'info' => { 'nickname' => 'blah' },
      'credentials' => { 'token' => 'blah', 'secret' => 'blah' }
    }
  end

end
