require 'rails_helper'

describe 'home/_seeds.html.haml', type: "view" do
  before(:each) do
    @owner = FactoryBot.create(:london_member)
    @seed = FactoryBot.create(:tradable_seed, owner: @owner)
    render
  end

  it 'has a heading' do
    assert_select 'h2', 'Seeds available to trade'
  end

  it 'lists seeds' do
    rendered.should have_content @seed.tradable_to
    rendered.should have_content @seed.owner.location
    assert_select 'a', href: seed_path(@seed)
  end
end
