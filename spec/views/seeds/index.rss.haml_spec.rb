require 'spec_helper'

describe 'seeds/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context 'all seeds' do
    before(:each) do
      @seed = FactoryGirl.create(:seed)
      @tradable = FactoryGirl.create(:tradable_seed)
      assign(:seeds, [ @seed, @tradable ])
      render
    end

    it 'shows RSS feed title' do
      rendered.should contain "Recent seeds from all members"
    end

    it 'has a useful item title' do
      rendered.should contain "#{@seed.owner}'s #{@seed.crop} seeds"
    end

    it 'shows the seed count' do
      rendered.should contain "Quantity: #{@seed.quantity}"
    end

    it 'shows the plant_before date' do
      rendered.should contain "Plant before: #{@seed.plant_before.to_s}"
    end

    it 'mentions that one seed is tradable' do
      rendered.should contain "Will trade #{@tradable.tradable_to} from #{@tradable.owner.location}"
    end

  end

  context "one member's seeds" do
    before(:each) do
      @seed = FactoryGirl.create(:seed)
      assign(:seeds, [ @seed ])
      assign(:owner, @seed.owner)
      render
    end

    it 'shows RSS feed title' do
      rendered.should contain "Recent seeds from #{@seed.owner}"
    end
  end
end
