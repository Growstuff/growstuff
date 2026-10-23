# frozen_string_literal: true

require 'rails_helper'

describe 'devise/sessions/new.html.haml', type: "view" do
  context "logged in" do
    before do
      allow(@view).to receive_messages(resource: Member.new, resource_name: "member", resource_class: Member, devise_mapping: Devise.mappings[:member])
      render
    end

    it { expect(rendered).to have_content 'Keep me signed in' }
    it { expect(rendered).to have_content 'Password' }
  end
end
