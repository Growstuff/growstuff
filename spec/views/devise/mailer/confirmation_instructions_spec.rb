require 'rails_helper'

describe 'devise/mailer/confirmation_instructions.html.haml', :type => "view" do

  context "logged in" do
    before(:each) do
      @resource = FactoryGirl.create(:member)
      render
    end

    it 'should have a confirmation link' do
      rendered.should contain 'Confirm my account'
    end

    it 'should have a link to the homepage' do
      rendered.should contain root_url
    end
  end
end
