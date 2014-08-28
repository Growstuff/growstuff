require 'spec_helper'

describe Role do
  let(:member)  { FactoryGirl.create(:member) }

  subject do
    role = FactoryGirl.create(:role, name: 'Crop Wrangler')
    role.members << member
    role
  end

  it 'has members' do
    subject.members.first.should eq member
  end

  it 'has a slug' do
    subject.slug.should eq 'crop-wrangler'
  end

  describe '.crop_wranglers' do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    it 'return the crop wranglers that are members of that role' do
      expect(Role.crop_wranglers).to match_array(crop_wranglers)
    end
  end

  describe '.admins' do
    let!(:admins) { FactoryGirl.create_list(:admin_member, 3) }
    it 'return the members that have the role of admin' do
      expect(Role.admins).to match_array(admins)
    end
  end
end
