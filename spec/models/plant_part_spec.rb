# frozen_string_literal: true

require 'rails_helper'

describe PlantPart do
  it 'stringifies' do
    @pp = create(:plant_part)
    @pp.to_s.should eq @pp.name
  end

  it 'has crops' do
    @maize = create(:maize)
    @tomato = create(:tomato)
    @pp1 = create(:plant_part)
    @h1 = create(:harvest,
                 crop:       @tomato,
                 plant_part: @pp1)
    @h2 = create(:harvest,
                 crop:       @maize,
                 plant_part: @pp1)
    expect(@pp1.crops).to include @tomato
    expect(@pp1.crops).to include @maize
  end

  it "doesn't duplicate crops" do
    @maize = create(:maize)
    @pp1 = create(:plant_part)
    @h1 = create(:harvest,
                 crop:       @maize,
                 plant_part: @pp1)
    @h2 = create(:harvest,
                 crop:       @maize,
                 plant_part: @pp1)
    expect(@pp1.crops).to eq [@maize]
  end
end
