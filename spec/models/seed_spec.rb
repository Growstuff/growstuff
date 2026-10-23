# frozen_string_literal: true

require 'rails_helper'

describe Seed do
  let(:owner) { create(:owner, login_name: 'tamateapokaiwhenua') }
  let(:seed)  { build(:seed, owner:) }

  it 'saves a basic seed' do
    expect(seed.save).to be(true)
  end

  it "has a slug" do
    seed.save
    expect(seed.slug).to include('tamateapokaiwhenua-magic-bean')
  end

  describe 'quantity' do
    [99, 0].each do |quantity|
      context "with #{quantity}" do
        subject { build(:seed, quantity:) }

        it { is_expected.to be_valid }
      end
    end

    [nil, ''].each do |quantity|
      context "with #{quantity.inspect}" do
        subject { build(:seed, quantity:) }

        it { is_expected.to be_valid }
      end
    end

    [99.9, 'foo'].each do |quantity|
      context "with #{quantity.inspect}" do
        subject { build(:seed, quantity:) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe 'tradable_to' do
    %w(nowhere locally nationally internationally).each do |tradable_to|
      context "with #{tradable_to}" do
        subject(:seed) { build(:seed, tradable_to:) }

        it { is_expected.to be_valid }

        it 'derives tradable from it' do
          expect(seed.tradable).to be(tradable_to != 'nowhere')
        end
      end
    end

    context 'with an unknown value' do
      subject(:seed) { build(:seed, tradable_to: 'not valid') }

      it { is_expected.not_to be_valid }

      it 'explains the allowed values' do
        seed.valid?
        expect(seed.errors[:tradable_to]).to include(
          "You may only trade seed nowhere, locally, " \
          "nationally, or internationally"
        )
      end
    end

    [nil, ''].each do |tradable_to|
      context "with #{tradable_to.inspect}" do
        subject { build(:seed, tradable_to:) }

        it { is_expected.not_to be_valid }
      end
    end

    describe '.tradable' do
      let!(:tradable) { create(:tradable_seed) }
      let!(:untradable) { create(:untradable_seed) }

      it { expect(described_class.tradable).to include tradable }
      it { expect(described_class.tradable).not_to include untradable }
    end
  end

  {
    organic:  ['certified organic', 'non-certified organic', 'conventional/non-organic', 'unknown'],
    gmo:      ['certified GMO-free', 'non-certified GMO-free', 'GMO', 'unknown'],
    heirloom: %w(heirloom hybrid unknown)
  }.each do |field, values|
    describe field.to_s do
      values.each do |value|
        context "with #{value}" do
          subject { build(:seed, field => value) }

          it { is_expected.to be_valid }
        end
      end

      ['not valid', nil, ''].each do |value|
        context "with #{value.inspect}" do
          subject(:seed) { build(:seed, field => value) }

          it { is_expected.not_to be_valid }

          it 'has an error on the field' do
            seed.valid?
            expect(seed.errors[field]).not_to be_empty
          end
        end
      end
    end
  end

  describe 'plant_before_year' do
    let(:seed) { create(:seed) }

    it 'reads back the year of the stored date' do
      seed.update!(plant_before: Date.new(2027, 3, 4))
      expect(seed.plant_before_year).to eq 2027
    end

    it 'stores a given year as the last day of it' do
      seed.update!(plant_before_year: '2027')
      expect(seed.plant_before).to eq Date.new(2027, 12, 31)
    end

    it 'clears the date when given nothing' do
      seed.update!(plant_before_year: '')
      expect(seed.plant_before).to be_nil
    end

    it 'refuses something that is not a year' do
      seed.plant_before_year = 'next spring'
      expect(seed).not_to be_valid
      expect(seed.errors[:plant_before_year]).to be_present
    end

    it 'reads back what was typed when it was not a year, to correct' do
      seed.plant_before_year = 'next spring'
      expect(seed.plant_before_year).to eq 'next spring'
    end

    it 'refuses a year outside the sensible range' do
      seed.plant_before_year = '1234'
      expect(seed).not_to be_valid
    end
  end

  context 'expired' do
    it 'returns seeds with a plant_before date in the past' do
      expired_seed = create(:seed, plant_before: 1.day.ago)
      not_expired_seed = create(:seed, plant_before: 1.day.from_now)
      expect(described_class.expired).to include expired_seed
      expect(described_class.expired).not_to include not_expired_seed
    end

    it 'does not return finished seeds' do
      expired_seed = create(:seed, plant_before: 1.day.ago, finished: true)
      expect(described_class.expired).not_to include expired_seed
    end
  end

  context 'interesting' do
    it 'lists interesting seeds' do
      # to be interesting a seed must:
      # 1) be tradable
      # 2) the owner must have a location set

      located_member = create(:london_member)
      seed1 = create(:tradable_seed, owner: located_member)
      seed2 = create(:seed, owner: located_member)
      seed3 = create(:tradable_seed)
      seed4 = create(:seed)

      expect(described_class.interesting).to include seed1
      expect(described_class.interesting).not_to include seed2
      expect(described_class.interesting).not_to include seed3
      expect(described_class.interesting).not_to include seed4
      expect(described_class.interesting.size).to eq 1
    end
  end

  context 'photos' do
    let(:seed) { create(:seed) }

    before { seed.photos << create(:photo, owner: seed.owner) }

    it 'is found in has_photos scope' do
      expect(described_class.has_photos).to include(seed)
    end
  end

  context 'ancestry' do
    let(:parent_planting) { create(:planting) }
    let(:seed)            { create(:seed, parent_planting:, owner: parent_planting.owner) }

    it "seed has a parent planting" do
      expect(seed.parent_planting).to eq(parent_planting)
    end

    it "planting has a child seed" do
      expect(parent_planting.child_seeds).to eq [seed]
    end
  end

  context "finished" do
    describe 'has finished fields' do
      let(:seed) { create(:finished_seed) }

      it { expect(seed.finished).to be true }
      it { expect(seed.finished_at).to be_an_instance_of Date }
    end

    describe 'scopes' do
      let!(:seed)          { create(:seed)          }
      let!(:finished_seed) { create(:finished_seed) }

      describe 'has finished scope' do
        it { expect(described_class.finished).to include finished_seed }
        it { expect(described_class.finished).not_to include seed }
      end

      describe 'has current scope' do
        it { expect(described_class.current).to include seed }
        it { expect(described_class.current).not_to include finished_seed }
      end
    end
  end

  describe 'homepage' do
    subject { described_class.homepage_records(100) }

    let!(:tradable_seed) { create(:tradable_seed, finished: false)  }
    let!(:finished_seed)   { create(:tradable_seed, finished: true) }
    let!(:untradable_seed) { create(:untradable_seed)               }

    it { expect(subject.count).to eq 1 }
    it { expect(subject.first.id).to eq tradable_seed.id }
  end

  describe '.of_crop' do
    let(:tomato) { create(:crop, name: 'tomato') }
    let(:brandywine) { create(:crop, name: 'Brandywine tomato', parent: tomato) }
    let!(:variety_seed) { create(:seed, crop: brandywine) }
    let!(:parent_seed) { create(:seed, crop: tomato) }

    before { create(:seed, crop: create(:crop, name: 'cabbage')) }

    it { expect(described_class.of_crop(tomato)).to contain_exactly(variety_seed, parent_seed) }
    it { expect(described_class.of_crop(brandywine)).to contain_exactly(variety_seed) }
  end

  describe '.from_source' do
    let!(:own) { create(:seed, source: 'my own seed saving') }
    let!(:catalogue) { create(:seed, source: 'seed catalogue') }
    let!(:retail) { create(:seed, source: 'retail outlet') }
    let!(:bank) { create(:seed, source: 'seed bank or similar institution') }
    let!(:traded) { create(:seed, source: 'traded from another person') }

    it { expect(described_class.from_source('own')).to contain_exactly(own) }
    it { expect(described_class.from_source('bought')).to contain_exactly(catalogue, retail, bank) }
    it { expect(described_class.from_source('traded')).to contain_exactly(traded) }
    it { expect { described_class.from_source('gifted') }.to raise_error(KeyError) }
  end

  describe '.heirlooms' do
    let!(:heirloom) { create(:seed, heirloom: 'heirloom') }

    before { create(:seed, heirloom: 'hybrid') }

    it { expect(described_class.heirlooms).to contain_exactly(heirloom) }
  end

  describe '#past_sow_by?' do
    it { expect(build(:seed, plant_before: Date.new(2020, 12, 31))).to be_past_sow_by }
    it { expect(build(:seed, plant_before: 1.year.from_now.to_date)).not_to be_past_sow_by }
    it { expect(build(:seed, plant_before: nil)).not_to be_past_sow_by }
  end

  describe '#heirloom_kind' do
    it { expect(build(:seed, heirloom: 'heirloom').heirloom_kind).to eq 'heirloom' }
    it { expect(build(:seed, heirloom: 'hybrid').heirloom_kind).to eq 'hybrid' }
    it { expect(build(:seed, heirloom: 'unknown').heirloom_kind).to be_nil }
  end
end
