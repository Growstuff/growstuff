require 'rails_helper'
describe 'devise/mailer/unlock_instructions.html.haml', type: "view" do
  context "logged in" do
    before(:each) do
      @resource = FactoryBot.create(:member)
      render
    end

    it "should explain what's happened" do
      rendered.should have_content "account has been locked"
    end

    it "should have an unlock link" do
      rendered.should have_content "Unlock my account"
    end
  end
end
