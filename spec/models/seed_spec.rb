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
    expect(seed.slug).to match(/tamateapokaiwhenua-magic-bean/)
  end

  describe 'quantity' do
    it 'allows integer quantities' do
      @seed = build(:seed, quantity: 99)
      expect(@seed).to be_valid
    end

    it "doesn't allow decimal quantities" do
      @seed = build(:seed, quantity: 99.9)
      expect(@seed).not_to be_valid
    end

    it "doesn't allow non-numeric quantities" do
      @seed = build(:seed, quantity: 'foo')
      expect(@seed).not_to be_valid
    end

    [nil, ''].each do |blank|
      it "allows a quantity of #{blank.inspect}" do
        expect(build(:seed, quantity: blank)).to be_valid
      end
    end
  end

  describe 'tradable' do
    it 'all valid tradable_to values should work' do
      %w(nowhere locally nationally internationally).each do |t|
        @seed = build(:seed, tradable_to: t)
        expect(@seed).to be_valid
      end
    end

    context 'with an invalid tradable_to value' do
      subject(:seed) { build(:seed, tradable_to: 'not valid') }

      it { is_expected.not_to be_valid }

      it 'explains where seed may be traded' do
        seed.validate
        expect(seed.errors[:tradable_to]).to include(
          "You may only trade seed nowhere, locally, " \
          "nationally, or internationally"
        )
      end
    end

    [nil, ''].each do |blank|
      it "does not allow a tradable_to of #{blank.inspect}" do
        expect(build(:seed, tradable_to: blank)).not_to be_valid
      end
    end

    it 'is not tradable when traded nowhere' do
      expect(create(:seed, tradable_to: 'nowhere').tradable).to be false
    end

    %w(locally nationally internationally).each do |where|
      it "is tradable when traded #{where}" do
        expect(create(:seed, tradable_to: where).tradable).to be true
      end
    end

    it 'recognises a tradable seed' do
      expect(create(:tradable_seed).tradable).to be true
    end

    it 'recognises an untradable seed' do
      expect(create(:untradable_seed).tradable).to be false
    end

    context 'with tradable and untradable seeds' do
      let!(:tradable) { create(:tradable_seed) }
      let!(:untradable) { create(:untradable_seed) }

      it('includes the tradable seed') { expect(described_class.tradable).to include tradable }
      it('leaves out the untradable seed') { expect(described_class.tradable).not_to include untradable }
    end
  end

  describe 'organic, gmo, heirloom' do
    it 'all valid organic values should work' do
      ['certified organic', 'non-certified organic',
       'conventional/non-organic', 'unknown'].each do |t|
        @seed = build(:seed, organic: t)
        expect(@seed).to be_valid
      end
    end

    it 'all valid GMO values should work' do
      ['certified GMO-free', 'non-certified GMO-free',
       'GMO', 'unknown'].each do |t|
        @seed = build(:seed, gmo: t)
        expect(@seed).to be_valid
      end
    end

    it 'all valid heirloom values should work' do
      %w(heirloom hybrid unknown).each do |t|
        @seed = build(:seed, heirloom: t)
        expect(@seed).to be_valid
      end
    end

    %i(organic gmo heirloom).each do |field|
      it "refuses an invalid #{field} value" do
        expect(build(:seed, field => 'not valid')).not_to be_valid
      end

      it "gives an error for an invalid #{field} value" do
        seed = build(:seed, field => 'not valid')
        seed.validate
        expect(seed.errors[field]).not_to be_empty
      end

      [nil, ''].each do |blank|
        it "does not allow #{field} to be #{blank.inspect}" do
          expect(build(:seed, field => blank)).not_to be_valid
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

    context 'with something that is not a year' do
      before do
        seed.plant_before_year = 'next spring'
        seed.validate
      end

      it { expect(seed).not_to be_valid }
      it { expect(seed.errors[:plant_before_year]).to be_present }
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

  context 'when expired' do
    context 'with a plant_before date in the past and one in the future' do
      let!(:expired_seed) { create(:seed, plant_before: 1.day.ago) }
      let!(:not_expired_seed) { create(:seed, plant_before: 1.day.from_now) }

      it('returns the past one') { expect(described_class.expired).to include expired_seed }
      it('leaves out the future one') { expect(described_class.expired).not_to include not_expired_seed }
    end

    it 'does not return finished seeds' do
      expired_seed = create(:seed, plant_before: 1.day.ago, finished: true)
      expect(described_class.expired).not_to include expired_seed
    end
  end

  describe 'photos' do
    let(:seed) { create(:seed) }

    before { seed.photos << create(:photo, owner: seed.owner) }

    it 'is found in has_photos scope' do
      expect(described_class.has_photos).to include(seed)
    end
  end

  describe 'ancestry' do
    let(:parent_planting) { create(:planting) }
    let(:seed)            { create(:seed, parent_planting:, owner: parent_planting.owner) }

    it "seed has a parent planting" do
      expect(seed.parent_planting).to eq(parent_planting)
    end

    it "planting has a child seed" do
      expect(parent_planting.child_seeds).to eq [seed]
    end
  end

  context "when finished" do
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
    it { expect(described_class.from_source('catalogue')).to contain_exactly(catalogue) }
    it { expect(described_class.from_source('retail')).to contain_exactly(retail) }
    it { expect(described_class.from_source('bank')).to contain_exactly(bank) }
    it { expect(described_class.from_source('traded')).to contain_exactly(traded) }
    it { expect { described_class.from_source('gifted') }.to raise_error(KeyError) }
  end

  describe '.planted and .not_planted' do
    let!(:planted_seed) { create(:seed) }
    let!(:unplanted_seed) { create(:seed) }

    before { create_list(:planting, 2, parent_seed: planted_seed) }

    it { expect(described_class.planted).to contain_exactly(planted_seed) }
    it { expect(described_class.not_planted).to contain_exactly(unplanted_seed) }

    # Plantings have finished columns too, so the join must not make them ambiguous.
    it { expect(described_class.not_planted.active).to contain_exactly(unplanted_seed) }
    it { expect(described_class.not_planted.current.finished).to be_empty }
    it { expect(described_class.not_planted.expired).to contain_exactly(unplanted_seed) }
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

  describe '.sow_now_months' do
    it 'is this month early in it' do
      expect(described_class.sow_now_months(Date.new(2026, 11, 4))).to eq [11]
    end

    it 'includes next month near the end of this one' do
      expect(described_class.sow_now_months(Date.new(2026, 11, 25))).to eq [11, 12]
    end

    it 'goes on into January from December' do
      expect(described_class.sow_now_months(Date.new(2026, 12, 28))).to eq [12, 1]
    end
  end

  describe '.sown_in' do
    let!(:september) { create(:seed, sow_months: [9, 10]) }

    before { create(:seed, sow_months: [3]) }

    it { expect(described_class.sown_in(10)).to contain_exactly(september) }
    it { expect(described_class.sown_in([8, 9])).to contain_exactly(september) }
    it { expect(described_class.sown_in([])).to be_empty }
  end
end
