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
    let(:crop_wrangler_role) { FactoryGirl.create :crop_wrangler }
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3, roles: [crop_wrangler_role]) }
    it 'return the crop wranglers that are members of that role' do
      expect(Role.crop_wranglers).to eq(crop_wranglers)
    end
  end
end
