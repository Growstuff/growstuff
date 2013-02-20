require 'spec_helper'

describe Role do
  before(:each) do
    @member = FactoryGirl.create(:member)
    @role = FactoryGirl.create(:role)
    @role.members << @member
  end

  it 'has members' do
    @role.members.first.should eq @member
  end

  it 'has a slug' do
    @role.slug.should eq 'moderator'
  end
end
