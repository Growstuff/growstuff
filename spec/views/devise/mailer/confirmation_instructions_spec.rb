require 'spec_helper'

describe 'devise/mailer/confirmation_instructions.html.haml', :type => "view" do

  context "logged in" do
    before(:each) do
        @resource = mock_model(User)
        @resource.stub!(:email).and_return("example@example.com")
        @resource.stub!(:confirmation_token).and_return("fred")
        render
    end

    it 'should have a confirmation link' do
        rendered.should contain 'Confirm my account'
    end
  end
end
