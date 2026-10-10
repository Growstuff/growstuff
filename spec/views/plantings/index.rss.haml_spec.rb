# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/index.rss.haml' do
  before do
    allow(view).to receive(:current_user).and_return(nil)
  end

  context 'all plantings' do
    before do
      @planting = create(:planting)
      @sunny = create(:sunny_planting)
      @seedling = create(:seedling_planting)
      assign(:plantings, Planting.all)
      render
    end

    it 'shows RSS feed title' do
      expect(rendered).to have_content "Recent plantings from all members"
    end

    it 'item title shows owner and location' do
      expect(rendered).to have_content "#{@planting.crop.name} in #{@planting.location}"
    end

    it 'shows sunniness' do
      expect(rendered).to have_content 'Sunniness: sun'
    end

    it 'shows propagation method' do
      expect(rendered).to have_content 'Planted from: seedling'
    end
  end

  context "one person's plantings" do
    before do
      @planting = create(:planting)
      assign(:plantings, [@planting])
      assign(:owner, @planting.owner)
      render
    end

    it 'shows title for single member' do
      expect(rendered).to have_content "Recent plantings from #{@planting.owner}"
    end
  end
end
