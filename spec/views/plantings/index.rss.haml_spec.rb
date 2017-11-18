require 'rails_helper'

describe 'plantings/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context 'all plantings' do
    before :each do
      @planting = FactoryBot.create(:planting)
      @sunny = FactoryBot.create(:sunny_planting)
      @seedling = FactoryBot.create(:seedling_planting)
      assign(:plantings, [@planting, @sunny, @seedling])
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent plantings from all members"
    end

    it 'item title shows owner and location' do
      rendered.should have_content "#{@planting.crop} in #{@planting.location}"
    end

    it 'shows formatted content of posts' do
      rendered.should have_content "This is a <em>really</em> good plant."
    end

    it 'shows sunniness' do
      rendered.should have_content 'Sunniness: sun'
    end

    it 'shows propagation method' do
      rendered.should have_content 'Planted from: seedling'
    end
  end

  context "one person's plantings" do
    before :each do
      @planting = FactoryBot.create(:planting)
      assign(:plantings, [@planting])
      assign(:owner, @planting.owner)
      render
    end

    it 'shows title for single member' do
      rendered.should have_content "Recent plantings from #{@planting.owner}"
    end
  end
end
