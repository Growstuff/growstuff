# frozen_string_literal: true

require 'rails_helper'

describe "show photo page" do
  context "when signed in as a member" do
    include_context 'signed in member'
    context "when linked to a planting" do
      let(:planting) { create(:planting) }
      let(:photo) { create(:photo, owner: planting.owner) }

      context "when linked to a planting" do
        before do
          planting.photos << photo
          visit photo_path(photo)
        end

        it { expect(page).to have_link href: planting_path(planting) }

        it { expect(page).to have_link planting.crop.name }
      end
    end

    context "when linked to a harvest" do
      let(:photo) { create(:photo, owner: harvest.owner) }
      let(:harvest) { create(:harvest) }

      context "when linked to a harvest" do
        before do
          harvest.photos << photo
          visit photo_path(photo)
        end

        it { expect(page).to have_link href: harvest_path(harvest) }
        it { expect(page).to have_link harvest.crop.name }
      end
    end

    context "when linked to a garden" do
      let(:photo) { create(:photo, owner: garden.owner) }
      let(:garden) { create(:garden) }

      context "when linked to a garden" do
        before do
          garden.photos << photo
          visit photo_path(photo)
          page.percy_snapshot(page, name: 'Show photo of a garden')
        end

        it { expect(page).to have_link href: garden_path(garden) }
      end
    end

    context "when linked to a seed" do
      let(:photo) { create(:photo, owner: seed.owner) }
      let(:seed) { create(:seed) }

      context "when linked to a seed" do
        before do
          seed.photos << photo
          visit photo_path(photo)
        end

        it { expect(page).to have_link href: seed_path(seed) }
        it { expect(page).to have_link seed.crop.name }
      end
    end
  end
end
