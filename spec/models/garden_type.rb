require 'rails_helper'

describe GardenType do
  let(:owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: owner, name: 'Free Carrots') }
  let(:container) { FactoryBot.create(:container, name: "fake hole in the ground") }

  it "should have a name" do
    container = FactoryBot.build(:container, name: "organic")
    container.should be_valid
  end

  it "doesn't allow a nil name" do
    container = FactoryBot.build(:container, name: nil)
    container.should_not be_valid
  end

  it "doesn't allow a blank name" do
    container = FactoryBot.build(:container, name: "")
    container.should_not be_valid
  end

  it "doesn't allow a name with only spaces" do
    container = FactoryBot.build(:container, name: "    ")
    container.should_not be_valid
  end

  it "destroys plots when deleted" do
    container = FactoryBot.create(:container, name: "Massive Flower Pot")
    @plot1 = FactoryBot.create(:plot, garden: garden, container: container)
    @plot2 = FactoryBot.create(:plot, garden: garden, container: container)
    container.plots.size.should eq(2)
    all = Plot.count
    container.destroy
    Plot.count.should eq(all - 2)
  end
end
