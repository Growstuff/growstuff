# frozen_string_literal: true

require 'rails_helper'

describe "show photo page" do
  context "signed in member" do
    include_context 'signed in member'
    context "linked to planting" do
      let(:planting) { create :planting }
      let(:photo) { create :photo, owner: planting.owner }

      context "shows linkback to planting" do
        before do
          planting.photos << photo
          visit photo_path(photo)
        end

        it {
          expect(page).to have_link "#{planting.crop.name} planting in #{planting.garden.name} by #{planting.owner}",
                                    href: planting_path(planting)
        }
        it { expect(page).to have_link planting.crop.name }
      end
    end

    context "linked to harvest" do
      let(:photo) { create :photo, owner: harvest.owner }
      let(:harvest) { create :harvest }

      context "shows linkback to harvest" do
        before do
          harvest.photos << photo
          visit photo_path(photo)
        end

        it { expect(page).to have_link "#{harvest.crop.name} harvest by #{harvest.owner}", href: harvest_path(harvest) }
        it { expect(page).to have_link harvest.crop.name }
      end
    end

    context "linked to garden" do
      let(:photo) { create :photo, owner: garden.owner }
      let(:garden) { create :garden }

      context "shows linkback to garden" do
        before do
          garden.photos << photo
          visit photo_path(photo)
          Percy.snapshot(page, name: 'Show photo of a garden')
        end

        it { expect(page).to have_link "garden named \"#{garden.name}\" by #{garden.owner}", href: garden_path(garden) }
      end
    end

    context "linked to seed" do
      let(:photo) { create :photo, owner: seed.owner }
      let(:seed) { create :seed }

      context "shows linkback to seed" do
        before do
          seed.photos << photo
          visit photo_path(photo)
        end

        it { expect(page).to have_link "#{seed.crop.name} seeds belonging to #{seed.owner}", href: seed_path(seed) }
        it { expect(page).to have_link seed.crop.name }
      end
    end
  end
end
