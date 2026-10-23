# frozen_string_literal: true

require 'rails_helper'

describe 'devise/confirmations/new.html.haml', type: "view" do
  before do
    allow(@view).to receive_messages(resource: Member.new, resource_name: "member", resource_class: Member, devise_mapping: Devise.mappings[:member])
    render
  end

  it 'contains a login field' do
    expect(rendered).to have_content "Enter either your login name or your email address"
  end
end
