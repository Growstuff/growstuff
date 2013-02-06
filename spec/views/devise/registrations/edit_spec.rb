require 'spec_helper'

describe 'devise/registrations/edit.html.haml', :type => "view" do

  context "logged in" do
    before(:each) do
      controller.stub(:current_user) { nil }
      @member = FactoryGirl.create(:member)
      controller.stub(:current_member) { @member }
      @view.stub(:resource).and_return(@member)
      @view.stub(:resource_name).and_return("member")
      @view.stub(:resource_class).and_return(Member)
      @view.stub(:devise_mapping).and_return(Devise.mappings[:member])
      render
    end

    it 'should have some fields' do
        rendered.should contain 'Email'
    end

    it 'should have an email section' do
      assert_select "h2", "Email address"
    end

    it 'should have a password section' do
      assert_select "h2", "Change password"
    end

  end
end
