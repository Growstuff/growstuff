require 'spec_helper'

describe 'home/_crops.html.haml', :type => "view" do
  before(:each) do
    @crop = FactoryGirl.create(:crop)
    assign(:crops, [@crop])
    assign(:recent_crops, [@crop])
    @planting = FactoryGirl.create(:planting)
    assign(:plantings, [@planting])
    render
  end

  it 'shows crops section' do
    assert_select 'h2', :text => 'Some of our crops'
    assert_select "a[href=#{crop_path(@crop)}]"
  end

  it 'shows plantings section' do
    assert_select 'h2', :text => 'Recently planted'
    rendered.should contain @planting.location
  end

  it 'shows recently added crops' do
    assert_select 'h2', :text => 'Recently planted'
  end

  it 'includes a link to all crops' do
    assert_select "a[href=#{crops_path}]", :text => "View all crops"
  end
end
