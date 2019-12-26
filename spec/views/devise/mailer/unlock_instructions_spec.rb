# frozen_string_literal: true

require 'rails_helper'
describe 'devise/mailer/unlock_instructions.html.haml', type: "view" do
  context "logged in" do
    before do
      @resource = FactoryBot.create(:member)
      render
    end

    it "explains what's happened" do
      rendered.should have_content "account has been locked"
    end

    it "has an unlock link" do
      rendered.should have_content "Unlock my account"
    end
  end
end
