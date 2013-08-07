require 'spec_helper'

describe "crops/_popover" do
  before(:each) do
    @tomato = FactoryGirl.create(:tomato)
    @sn = FactoryGirl.create(:solanum_lycopersicum, :crop => @tomato)
    @planting = FactoryGirl.create(:planting, :crop => @tomato)
    render :partial => 'crops/popover', :locals => { :crop => @tomato }
  end

  it 'has a scientific name' do
    rendered.should contain 'Solanum lycopersicum'
  end

  it 'shows count of plantings' do
    rendered.should contain '1 time'
  end

end
