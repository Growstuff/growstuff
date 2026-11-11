# frozen_string_literal: true

require 'rails_helper'

describe GardensHelper do
  describe '#soil_ph_description' do
    subject(:description) { helper.soil_ph_description(ph) }

    { 0 => :very_acidic, 3.99 => :very_acidic, 4 => :acidic,
      5.99 => :acidic, 6 => :slightly_acidic, 6.99 => :slightly_acidic,
      7 => :neutral, 7.01 => :slightly_basic, 8 => :slightly_basic,
      8.01 => :basic, 10 => :basic, 10.01 => :very_basic,
      14 => :very_basic }.each do |value, band|
      context "with a pH of #{value}" do
        let(:ph) { BigDecimal(value.to_s) }

        it "describes the reading as #{band}" do
          expect(description).to eq(I18n.t("soil_ph_readings.scale.#{band}"))
        end
      end
    end

    context 'without a reading' do
      let(:ph) { nil }

      it 'has no description' do
        expect(description).to be_nil
      end
    end
  end

  describe "garden description" do
    it "is missing" do
      garden = create(:garden,
                      description: nil)
      result = helper.display_garden_description(garden)
      expect(result).to eq "no description provided."
    end

    it "is less than 130 characters long" do
      garden = create(:garden,
                      description: 'a' * 20)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 20
    end

    it "is 130 characters long" do
      garden = create(:garden,
                      description: 'a' * 130)
      result = helper.display_garden_description(garden)
      expect(result).to eq 'a' * 130
    end

    it "is more than 130 characters long" do
      garden = create(:garden,
                      description: 'a' * 140)
      result = helper.display_garden_description(garden)
      expect(result).to eq ('a' * 126) + '...' + ' ' + link_to("Read more", garden_path(garden))
    end
  end

  describe '#garden_distance' do
    subject(:distance) { helper.garden_distance(garden) }

    let(:viewer) { build_stubbed(:member, latitude: -41.29, longitude: 174.78) }
    let(:garden) { build_stubbed(:garden, latitude: -36.85, longitude: 174.76) }

    before { allow(helper).to receive(:current_member).and_return(viewer) }

    context 'when both have a location' do
      it { is_expected.to match(/\Aabout \d+ km from you\z/) }
    end

    context 'when the garden has no location' do
      let(:garden) { build_stubbed(:garden, latitude: nil, longitude: nil) }

      it { is_expected.to be_nil }
    end

    context 'when the viewer owns the garden' do
      let(:garden) { build_stubbed(:garden, owner: viewer, latitude: -36.85, longitude: 174.76) }

      it { is_expected.to be_nil }
    end

    context 'when nobody is signed in' do
      let(:viewer) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#garden_details' do
    subject(:details) { helper.garden_details(garden) }

    let(:garden) { build_stubbed(:garden, location: 'Wellington', area: 24, area_unit: 'square metre', garden_type: build_stubbed(:garden_type, name: 'Backyard')) }

    before { allow(helper).to receive(:current_member).and_return(nil) }

    it 'joins the location, type and area' do
      expect(details).to eq '<a href="/places/Wellington">Wellington</a> · Backyard · 24 square metres'
    end

    context 'with nothing known' do
      let(:garden) { build_stubbed(:garden, location: nil, area: nil, area_unit: nil, garden_type: nil) }

      it { is_expected.to eq '' }
    end
  end

  describe '#garden_type_options' do
    it 'lists the types by name, with their ids' do
      zed = create(:garden_type, name: 'Zed')
      ant = create(:garden_type, name: 'Ant')
      expect(helper.garden_type_options).to eq [['Ant', ant.id], ['Zed', zed.id]]
    end
  end

  describe '#temperature_text' do
    it 'rounds to a tenth of a degree' do
      expect(helper.temperature_text(31.44)).to eq '31.4°C'
    end

    it 'says when it is not known' do
      expect(helper.temperature_text(nil)).to eq 'not known'
    end
  end

  describe '#garden_temperatures' do
    let(:garden) { build_stubbed(:garden, location_wikidata_id: 'Q1', highest_temp_c: 31.4, lowest_temp_c: nil) }

    it 'says the hottest and coldest, crediting Wikidata' do
      expect(helper.garden_temperatures(garden)).to include('hottest 31.4°C, coldest not known')
    end

    it 'links to the Wikidata entry' do
      expect(helper.garden_temperatures(garden)).to include('href="https://www.wikidata.org/wiki/Q1"')
    end
  end

  describe '#garden_planter_props' do
    let(:garden) { build_stubbed(:garden) }

    it 'names the garden the dialog plants in' do
      expect(helper.garden_planter_props(garden)[:garden]).to eq(id: garden.id, name: garden.name)
    end
  end
end
