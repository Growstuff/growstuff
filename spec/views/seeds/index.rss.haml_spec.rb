# frozen_string_literal: true

require 'rails_helper'

describe 'seeds/index.rss.haml', search: true do
  before do
    controller.stub(:current_user) { nil }
  end

  context 'all seeds' do
    before do
      @seed = FactoryBot.create(:seed)
      @tradable = FactoryBot.create(:tradable_seed)
      Seed.searchkick_index.refresh
      assign(:seeds, Seed.search('*', load: false))
      render
    end

    it 'shows RSS feed title' do
      expect(rendered).to have_content "Recent seeds from all members"
    end

    it 'has a useful item title' do
      expect(rendered).to have_content "#{@seed.owner.login_name}'s #{@seed.crop} seeds"
    end

    it 'shows the seed count' do
      expect(rendered).to have_content "Quantity: #{@seed.quantity}"
    end

    it 'shows the plant_before date' do
      expect(rendered).to have_content "Plant before: #{@seed.plant_before.to_s(:ymd)}"
    end

    it 'mentions that one seed is tradable' do
      expect(rendered).to have_content "Will trade #{@tradable.tradable_to} from #{@tradable.owner.location}"
    end
  end

  context "one member's seeds" do
    before do
      @seed = FactoryBot.create(:seed)
      assign(:seeds, [@seed])
      assign(:owner, @seed.owner)
      Seed.reindex
      render
    end

    it 'shows RSS feed title' do
      expect(rendered).to have_content "Recent seeds from #{@seed.owner}"
    end
  end
end
