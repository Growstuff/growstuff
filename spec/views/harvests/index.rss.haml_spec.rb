# frozen_string_literal: true

require 'rails_helper'

describe 'harvests/index.rss.haml', :search do
  before do
    controller.stub(:current_user) { nil }
    @member = FactoryBot.create(:member)
    @tomato = FactoryBot.create(:tomato)

    @harvest1 = FactoryBot.create :harvest, crop: @tomato
    @harvest2 = FactoryBot.create :harvest, crop: @tomato
    @harvest3 = FactoryBot.create :harvest, crop: @tomato

    Harvest.searchkick_index.refresh
    assign(:harvests, Harvest.search(load: false))
  end

  context 'all harvests' do
    before { render }
    it 'shows RSS feed title' do
      expect(rendered).to have_content "Recent harvests from all members"
    end

    it 'shows formatted content of harvest posts' do
      expect(rendered).to have_content "<p>Quantity: "
    end
  end

  context 'for one crop' do
    before do
      assign(:crop, @tomato)
      render
    end
    it "displays crop's name in title" do
      expect(rendered).to have_content @tomato.name
    end
  end
end
