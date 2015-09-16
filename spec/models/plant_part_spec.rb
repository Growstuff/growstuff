require 'rails_helper'

describe PlantPart do
  it 'stringifies' do
    @pp = FactoryGirl.create(:plant_part)
    "#{@pp}".should eq @pp.name
  end

  it 'has crops' do
    @maize = FactoryGirl.create(:maize)
    @tomato = FactoryGirl.create(:tomato)
    @pp1 = FactoryGirl.create(:plant_part)
    @h1 = FactoryGirl.create(:harvest,
      :crop => @tomato,
      :plant_part => @pp1
    )
    @h2 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp1
    )
    @pp1.crops.should include @tomato
    @pp1.crops.should include @maize
  end

  it "doesn't duplicate crops" do
    @maize = FactoryGirl.create(:maize)
    @pp1 = FactoryGirl.create(:plant_part)
    @h1 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp1
    )
    @h2 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp1
    )
    @pp1.crops.should eq [@maize]
  end

end
