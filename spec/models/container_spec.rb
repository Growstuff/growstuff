require 'rails_helper'

describe Container do
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
    garden = FactoryBot.build(:container, description: "    ")
    garden.should_not be_valid
  end
end
