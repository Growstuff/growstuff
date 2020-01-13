# frozen_string_literal: true

require 'rails_helper'

describe 'seeds/index.rss.haml', :search do
  before do
    controller.stub(:current_user) { nil }
  end

  shared_examples 'displays seed in rss feed' do
    it 'has a useful item title' do
      expect(rendered).to have_content "#{seed.owner.login_name}'s #{seed.crop.name} seeds"
    end

    it 'shows the seed count' do
      expect(rendered).to have_content "Quantity: #{seed.quantity}"
    end

    it 'shows the plant_before date' do
      expect(rendered).to have_content "Plant before: #{seed.plant_before.to_s(:ymd)}"
    end
  end

  context 'all seeds' do
    let!(:seed) { FactoryBot.create(:seed) }
    let!(:tradable) { FactoryBot.create(:tradable_seed) }
    before do
      Seed.searchkick_index.refresh
      assign(:seeds, Seed.search(load: false))
      render
    end

    include_examples 'displays seed in rss feed'

    it 'shows RSS feed title' do
      expect(rendered).to have_content "Recent seeds from all members"
    end

    it 'mentions that one seed is tradable' do
      expect(rendered).to have_content "Will trade #{tradable.tradable_to} from #{tradable.owner.location}"
    end

    it "does not offer untradable seed as tradeable" do
      expect(rendered).not_to have_content "Will trade #{seed.tradable_to} from #{seed.owner.location}"
    end
  end

  context "one member's seeds" do
    let!(:seed) { FactoryBot.create(:seed) }

    before do
      assign(:owner, seed.owner)
      Seed.searchkick_index.refresh
      assign(:seeds, Seed.search(load: false))
      render
    end

    it 'shows RSS feed title' do
      expect(rendered).to have_content "Recent seeds from #{seed.owner}"
    end

    include_examples 'displays seed in rss feed'
  end
end
