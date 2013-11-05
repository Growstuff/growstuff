require 'spec_helper'

describe "plant_parts/index" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @pp = FactoryGirl.create(:plant_part)
    assign(:plant_parts, [@pp])
  end

  it "renders a list of plant_parts" do
    render
    rendered.should contain @pp.name
    assert_select "a", :href => plant_part_path(@pp)
  end

end
