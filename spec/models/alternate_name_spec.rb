require 'rails_helper'

describe AlternateName do
  let(:an) { FactoryBot.create(:alternate_eggplant) }

  it 'should save a basic alternate name' do
    expect(an.save).to be(true)
  end

  it 'should be possible to add multiple alternate names to a crop' do
    crop = an.crop
    an2 = AlternateName.create(
      name: "really alternative tomato",
      crop_id: crop.id,
      creator_id: an.creator.id
    )
    crop.alternate_names << an2
    expect(crop.alternate_names).to include an
    expect(crop.alternate_names).to include an2
  end
end
