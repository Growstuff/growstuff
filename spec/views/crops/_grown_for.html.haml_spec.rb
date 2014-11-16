require 'rails_helper'

describe "crops/_grown_for" do
  before(:each) do
    @crop = FactoryGirl.create(:crop)
    @pp = FactoryGirl.create(:plant_part)
    @harvest = FactoryGirl.create(:harvest,
      :crop => @crop,
      :plant_part => @pp
    )
  end

  it 'shows plant parts' do
    render :partial => 'crops/grown_for', :locals => { :crop => @crop }
    rendered.should contain @pp.name
    assert_select "a", :href => plant_part_path(@pp)
  end
end
