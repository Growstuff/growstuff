# frozen_string_literal: true

require 'rails_helper'

describe Authentication do
  it 'creates an authentication' do
    @auth = create(:authentication)
    expect(@auth).to be_an_instance_of described_class
    expect(@auth.member).to be_an_instance_of Member
  end
end
