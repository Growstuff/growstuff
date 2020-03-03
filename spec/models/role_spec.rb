# frozen_string_literal: true

require 'rails_helper'

describe Role do
  subject do
    role = FactoryBot.create(:role, name: 'Crop Wrangler')
    role.members << member
    role
  end

  let(:member) { FactoryBot.create(:member) }

  it 'has members' do
    subject.members.first.should eq member
  end

  it 'has a slug' do
    subject.slug.should eq 'crop-wrangler'
  end

  describe '.crop_wranglers' do
    let!(:crop_wranglers) { FactoryBot.create_list(:crop_wrangling_member, 3) }

    it 'return the crop wranglers that are members of that role' do
      expect(described_class.crop_wranglers).to match_array(crop_wranglers)
    end
  end

  describe '.admins' do
    let!(:admins) { FactoryBot.create_list(:admin_member, 3) }

    it 'return the members that have the role of admin' do
      expect(described_class.admins).to match_array(admins)
    end
  end
end
