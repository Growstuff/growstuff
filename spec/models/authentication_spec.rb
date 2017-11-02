require 'rails_helper'

describe Authentication do
  it 'creates an authentication' do
    @auth = FactoryBot.create(:authentication)
    @auth.should be_an_instance_of Authentication
    @auth.member.should be_an_instance_of Member
  end
end
