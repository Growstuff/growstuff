require 'rails_helper'

describe GardenType do
  let(:owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: owner, name: 'Free Carrots') }
  let(:garden_type) { FactoryBot.create(:garden_type, name: "fake hole in the ground") }

  it "should have a name" do
    garden_type = FactoryBot.build(:garden_type, name: "organic")
    garden_type.should be_valid
  end

  it "doesn't allow a nil name" do
    garden_type = FactoryBot.build(:garden_type, name: nil)
    garden_type.should_not be_valid
  end

  it "doesn't allow a blank name" do
    garden_type = FactoryBot.build(:garden_type, name: "")
    garden_type.should_not be_valid
  end

  it "doesn't allow a name with only spaces" do
    garden_type = FactoryBot.build(:garden_type, name: "    ")
    garden_type.should_not be_valid
  end

  it "destroys plots when deleted" do
    garden_type = FactoryBot.create(:garden_type, name: "Massive Flower Pot")
    @plot1 = FactoryBot.create(:plot, garden: garden, garden_type: garden_type)
    @plot2 = FactoryBot.create(:plot, garden: garden, garden_type: garden_type)
    garden_type.plots.size.should eq(2)
    all = Plot.count
    garden_type.destroy
    Plot.count.should eq(all - 2)
  end
end
