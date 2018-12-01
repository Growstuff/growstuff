require 'rails_helper'

describe Container do
  let(:owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: owner, name: 'Free Carrots') }
  let(:container) { FactoryBot.create(:container, description: "fake hole in the ground") }

  it "should have a description" do
    container = FactoryBot.build(:container, description: "organic")
    container.should be_valid
  end

  it "doesn't allow a nil description" do
    container = FactoryBot.build(:container, description: nil)
    container.should_not be_valid
  end

  it "doesn't allow a blank description" do
    container = FactoryBot.build(:container, description: "")
    container.should_not be_valid
  end

  it "doesn't allow a description with only spaces" do
    container = FactoryBot.build(:container, description: "    ")
    container.should_not be_valid
  end

  it "destroys plots when deleted" do
    container = FactoryBot.create(:container, description: "Massive Flower Pot")
    @plot1 = FactoryBot.create(:plot, garden: garden, container: container)
    @plot2 = FactoryBot.create(:plot, garden: garden, container: container)
    container.plots.size.should eq(2)
    all = Plot.count
    container.destroy
    Plot.count.should eq(all - 2)
  end
end
