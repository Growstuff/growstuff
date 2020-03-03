# frozen_string_literal: true

require 'rails_helper'

describe AlternateName do
  let(:an) { FactoryBot.create(:alternate_eggplant) }

  it 'saves a basic alternate name' do
    expect(an.save).to be(true)
  end

  it 'is possible to add multiple alternate names to a crop' do
    crop = an.crop
    an2 = described_class.create(
      name:       "really alternative tomato",
      crop_id:    crop.id,
      creator_id: an.creator.id
    )
    crop.alternate_names << an2
    expect(crop.alternate_names).to include an
    expect(crop.alternate_names).to include an2
  end

  describe 'relationships' do
    let(:alternate_name) { FactoryBot.create :alternate_name, crop: crop, creator: member }
    let(:crop)   { FactoryBot.create :crop   }
    let(:member) { FactoryBot.create :member }

    it { expect(alternate_name.crop).to eq crop }
    it { expect(alternate_name.creator).to eq member }
    it { expect(member.created_alternate_names).to eq [alternate_name] }
  end
end
