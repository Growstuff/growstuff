require 'spec_helper'

describe AlternateName do
  before (:each) do
    @an = FactoryGirl.create(:alternate_tomato)
  end

  it 'should save a basic alternate name' do
    @an.save.should be_true
  end

  it 'should be possible to add multiple alternate names to a crop' do
    crop = @an.crop
    an2 = AlternateName.create(
      :name => "really alternative tomato",
      :crop_id => crop.id,
      :creator_id => @an.creator.id
    )
    crop.alternate_names << an2
    crop.alternate_names.should include @an
    crop.alternate_names.should include an2
  end

end
