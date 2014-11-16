require 'rails_helper'

describe 'home/_seeds.html.haml', :type => "view" do
  before(:each) do
    @owner = FactoryGirl.create(:london_member)
    @seed = FactoryGirl.create(:tradable_seed, :owner => @owner)
    render
  end

  it 'has a heading' do
    assert_select 'h2', 'Seeds available to trade'
  end

  it 'lists seeds' do
    assert_select "table"
    assert_select 'a', :href => crop_path(@seed.crop)
    assert_select 'a', :href => crop_path(@seed.owner)
    assert_select 'td', @seed.tradable_to
    assert_select 'td', @seed.owner.location
    assert_select 'a', :href => seed_path(@seed)
  end
end
