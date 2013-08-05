require 'spec_helper'

describe 'plantings/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context 'all plantings' do
    before :each do
      assign(:plantings, [
        FactoryGirl.create(:planting),
        FactoryGirl.create(:sunny_planting),
        FactoryGirl.create(:seedling_planting)
      ])
      render
    end

    it 'shows RSS feed title' do
      rendered.should contain "Recent plantings from all members"
    end

    it 'shows formatted content of posts' do
      rendered.should contain "This is a <em>really</em> good plant."
    end

    it 'shows sunniness' do
      rendered.should contain 'Sunniness: sun'
    end

    it 'shows propagation method' do
      rendered.should contain 'Planted from: seedling'
    end
  end

  context "one person's plantings" do
    before :each do
      @planting = FactoryGirl.create(:planting)
      assign(:plantings, [@planting ])
      assign(:owner, @planting.owner)
      render
    end

    it 'shows title for single member' do
      rendered.should contain "Recent plantings from #{@planting.owner}"
    end
  end
end
