require 'spec_helper'

describe 'devise/registrations/edit.html.erb', :type => "view" do

  context "logged in" do
    before(:each) do
      @view.stub(:resource).and_return(User.new)
      @view.stub(:resource_name).and_return("user")
      @view.stub(:resource_class).and_return(User)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:user])
      render
    end

    it 'should have some fields' do
        rendered.should contain 'Email'
        rendered.should contain 'Cancel my account'
    end
  end
end
