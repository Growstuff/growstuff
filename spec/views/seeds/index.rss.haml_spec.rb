require 'rails_helper'

describe 'seeds/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
  end

  context 'all seeds' do
    before(:each) do
      @seed = FactoryBot.create(:seed)
      @tradable = FactoryBot.create(:tradable_seed)
      assign(:seeds, [@seed, @tradable])
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent seeds from all members"
    end

    it 'has a useful item title' do
      rendered.should have_content "#{@seed.owner}'s #{@seed.crop} seeds"
    end

    it 'shows the seed count' do
      rendered.should have_content "Quantity: #{@seed.quantity}"
    end

    it 'shows the plant_before date' do
      rendered.should have_content "Plant before: #{@seed.plant_before}"
    end

    it 'mentions that one seed is tradable' do
      rendered.should have_content "Will trade #{@tradable.tradable_to} from #{@tradable.owner.location}"
    end
  end

  context "one member's seeds" do
    before(:each) do
      @seed = FactoryBot.create(:seed)
      assign(:seeds, [@seed])
      assign(:owner, @seed.owner)
      render
    end

    it 'shows RSS feed title' do
      rendered.should have_content "Recent seeds from #{@seed.owner}"
    end
  end
end
