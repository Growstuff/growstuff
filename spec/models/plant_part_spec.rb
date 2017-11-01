require 'rails_helper'

describe PlantPart do
  it 'stringifies' do
    @pp = FactoryBot.create(:plant_part)
    @pp.to_s.should eq @pp.name
  end

  it 'has crops' do
    @maize = FactoryBot.create(:maize)
    @tomato = FactoryBot.create(:tomato)
    @pp1 = FactoryBot.create(:plant_part)
    @h1 = FactoryBot.create(:harvest,
      crop: @tomato,
      plant_part: @pp1)
    @h2 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp1)
    @pp1.crops.should include @tomato
    @pp1.crops.should include @maize
  end

  it "doesn't duplicate crops" do
    @maize = FactoryBot.create(:maize)
    @pp1 = FactoryBot.create(:plant_part)
    @h1 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp1)
    @h2 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp1)
    @pp1.crops.should eq [@maize]
  end
end
