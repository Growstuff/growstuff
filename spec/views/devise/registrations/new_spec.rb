# frozen_string_literal: true

require 'rails_helper'

describe 'devise/registrations/new.html.haml', type: "view" do
  context "logged in" do
    before do
      allow(@view).to receive_messages(resource: Member.new, resource_name: "member", resource_class: Member, devise_mapping: Devise.mappings[:member])
      render
    end

    it 'has some fields' do
      expect(rendered).to have_content 'Email'
    end

    it 'has a checkbox for newsletter subscription' do
      assert_select "input[id=member_newsletter][type=checkbox]"
    end
  end
end
