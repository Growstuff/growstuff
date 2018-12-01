require 'rails_helper'

describe Plot do
  let(:owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden) }
  let(:container) { FactoryBot.create(:container) }
  let(:plot) { FactoryBot.create(:plot, garden: garden, container: container) }

  context "has valid attributes" do
    it "should have a garden" do
      plot.garden.description.should == "This is a **totally** cool garden"
    end
    it "should have a container" do
      plot.container.description.should == "homemade swamp"
    end
  end
end
