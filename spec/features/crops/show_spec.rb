# frozen_string_literal: true

require 'rails_helper'

describe "browse crops" do
  let(:tomato) { create(:tomato) }

  it "Show crop info" do
    visit crop_path(tomato)
    expect(page).to have_text 'tomato'
  end

  describe "shows varieties" do
    let!(:cherry) { create(:crop, name: 'cherry tomato', parent: tomato) }
    let!(:heirloom) { create(:crop, name: 'heirloom tomato', parent: tomato) }
    let!(:striped) { create(:crop, name: 'striped tomato', parent: heirloom) }

    before { visit crop_path(tomato) }

    it { expect(page).to have_link heirloom.name, href: crop_path(heirloom) }
    it { expect(page).to have_link cherry.name, href: crop_path(cherry) }
    it { expect(page).to have_link striped.name, href: crop_path(striped) }
  end

  describe "photos of a variety" do
    let(:variety) { create(:crop, name: 'cherry tomato', parent: tomato) }
    let(:planting) { create(:planting, crop: tomato) }
    let(:photo) { create(:photo, owner: planting.owner, title: 'A tomato on the vine') }

    before do
      planting.photos << photo
      visit crop_path(variety)
    end

    it "does not show the parent crop's photos" do
      expect(page).to have_no_css("img[alt='#{photo.title}']")
    end
  end

  describe "photos of a variety on the crop" do
    let(:variety) { create(:crop, name: 'cherry tomato', parent: tomato) }
    let(:planting) { create(:planting, crop: variety) }
    let(:photo) { create(:photo, owner: planting.owner, title: 'A cherry tomato on the vine') }

    before do
      planting.photos << photo
      visit crop_path(tomato)
    end

    it "shows the variety's photos" do
      expect(page).to have_css("img[alt='#{photo.title}']")
    end
  end

  describe "who has planted a variety" do
    let(:variety) { create(:crop, name: 'cherry tomato', parent: tomato) }

    before do
      create(:planting, crop: variety)
      visit crop_path(tomato)
    end

    it "shows the variety's name" do
      expect(page).to have_css(".crop-planting-variety", text: 'cherry tomato')
    end

    it "links to the variety" do
      expect(page).to have_link 'cherry tomato', href: crop_path(variety)
    end
  end

  describe "a member who has planted the crop many times" do
    let(:member) { create(:member) }

    before do
      create_list(:planting, 3, crop: tomato, owner: member)
      visit crop_path(tomato)
    end

    it "appears once in who has planted it" do
      expect(page).to have_css(".crop-planting", count: 1)
    end
  end

  describe "who has planted the crop itself" do
    before do
      create(:planting, crop: tomato)
      visit crop_path(tomato)
    end

    it "does not repeat the crop's name" do
      expect(page).to have_no_css(".crop-planting-variety")
    end
  end

  context "when the most recently created harvest is not the most recently harvested" do
    before { create_list(:harvest, 20, crop: tomato, harvested_at: 1.year.ago, created_at: 1.minute.ago) }

    let!(:most_recent_harvest) do
      create(:harvest, crop: tomato, harvested_at: 60.minutes.ago, created_at: 10.minutes.ago)
    end

    it "Shows most recently harvested harvest" do
      visit crop_path(tomato)
      expect(page).to have_link(href: harvest_path(most_recent_harvest))
    end
  end

  context "when the most recently created planting is not the most recently planted" do
    before { create_list(:planting, 20, crop: tomato, planted_at: 1.year.ago, created_at: 1.minute.ago) }

    let!(:most_recent_planting) do
      create(:planting, crop: tomato, planted_at: 60.minutes.ago, created_at: 10.minutes.ago)
    end

    it "Shows most recently planted planting" do
      visit crop_path(tomato)
      expect(page).to have_link(href: planting_path(most_recent_planting))
    end
  end
end
