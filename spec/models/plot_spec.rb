require 'rails_helper'

describe Plot do
  let(:owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: owner, name: "Magic Beanstalk") }
  let(:container) { FactoryBot.create(:container, description: "vertical") }
  let(:plot) { FactoryBot.create(:plot, garden: garden, container: container) }

  context "has valid attributes" do
    it "should have a garden and container" do
      plot.garden.should == garden
      plot.container.should == container
    end
  end
end
