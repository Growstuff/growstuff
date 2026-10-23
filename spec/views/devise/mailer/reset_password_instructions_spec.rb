# frozen_string_literal: true

require 'rails_helper'

describe 'devise/mailer/reset_password_instructions.html.haml', type: "view" do
  context "logged in" do
    before do
      @resource = mock_model(Member)
      allow(@resource).to receive_messages(email: "example@example.com", reset_password_token: "joe")
      render
    end

    it 'has some of the right text' do
      expect(rendered).to have_content 'Change my password'
      expect(rendered).to have_content 'Someone has requested a link to reset your password'
    end
  end
end
