require 'spec_helper'

describe "harvests/show" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @crop = FactoryGirl.create(:tomato)
    @harvest = assign(:harvest, FactoryGirl.create(:harvest, :crop => @crop))
    render
  end

  it "renders attributes" do
    rendered.should contain @crop.system_name
    rendered.should contain @harvest.harvested_at.to_s
  end

end
