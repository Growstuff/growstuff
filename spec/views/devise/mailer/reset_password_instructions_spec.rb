require 'spec_helper'

describe 'devise/mailer/reset_password_instructions.html.erb', :type => "view" do

  context "logged in" do
    before(:each) do
      @resource = mock_model(User)
      @resource.stub!(:email).and_return("example@example.com")
      @resource.stub!(:reset_password_token).and_return("joe")
      render
    end

    it 'should have some of the right text' do
        rendered.should contain 'Change my password'
        rendered.should contain 'please ignore this email'
    end
  end
end
