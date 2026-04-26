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

  context 'quantity' do
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

    it "allows blank quantities" do
      @seed = build(:seed, quantity: nil)
      expect(@seed).to be_valid
      @seed = build(:seed, quantity: '')
      expect(@seed).to be_valid
    end
  end

  context 'tradable' do
    it 'all valid tradable_to values should work' do
      %w(nowhere locally nationally internationally).each do |t|
        @seed = build(:seed, tradable_to: t)
        expect(@seed).to be_valid
      end
    end

    it 'refuses invalid tradable_to values' do
      @seed = build(:seed, tradable_to: 'not valid')
      expect(@seed).not_to be_valid
      expect(@seed.errors[:tradable_to]).to include(
        "You may only trade seed nowhere, locally, " \
        "nationally, or internationally"
      )
    end

    it 'does not allow nil or blank values' do
      @seed = build(:seed, tradable_to: nil)
      expect(@seed).not_to be_valid
      @seed = build(:seed, tradable_to: '')
      expect(@seed).not_to be_valid
    end

    it 'tradable gives the right answers' do
      @seed = create(:seed, tradable_to: 'nowhere')
      expect(@seed.tradable).to be false
      @seed = create(:seed, tradable_to: 'locally')
      expect(@seed.tradable).to be true
      @seed = create(:seed, tradable_to: 'nationally')
      expect(@seed.tradable).to be true
      @seed = create(:seed, tradable_to: 'internationally')
      expect(@seed.tradable).to be true
    end

    it 'recognises a tradable seed' do
      expect(create(:tradable_seed).tradable).to == true
    end

    it 'recognises an untradable seed' do
      expect(create(:untradable_seed).tradable).to == false
    end

    it 'scopes correctly' do
      @tradable = create(:tradable_seed)
      @untradable = create(:untradable_seed)
      expect(described_class.tradable).to include @tradable
      expect(described_class.tradable).not_to include @untradable
    end
  end

  context 'organic, gmo, heirloom' do
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

    it 'refuses invalid organic/GMO/heirloom values' do
      %i(organic gmo heirloom).each do |field|
        @seed = build(:seed, field => 'not valid')
        expect(@seed).not_to be_valid
        expect(@seed.errors[field]).not_to be_empty
      end
    end

    it 'does not allow nil or blank values' do
      %i(organic gmo heirloom).each do |field|
        @seed = build(:seed, field => nil)
        expect(@seed).not_to be_valid
        @seed = build(:seed, field => '')
        expect(@seed).not_to be_valid
      end
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

      @located_member = create(:london_member)
      @seed1 = create(:tradable_seed, owner: @located_member)
      @seed2 = create(:seed, owner: @located_member)
      @seed3 = create(:tradable_seed)
      @seed4 = create(:seed)

      expect(described_class.interesting).to include @seed1
      expect(described_class.interesting).not_to include @seed2
      expect(described_class.interesting).not_to include @seed3
      expect(described_class.interesting).not_to include @seed4
      expect(described_class.interesting.size).to == 1
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

  describe 'homepage', :search do
    subject { described_class.homepage_records(100) }

    let!(:tradable_seed) { create(:tradable_seed, :reindex, finished: false)  }
    let!(:finished_seed)   { create(:tradable_seed, :reindex, finished: true) }
    let!(:untradable_seed) { create(:untradable_seed, :reindex)               }

    before { described_class.reindex }

    it { expect(subject.count).to eq 1 }
    it { expect(subject.first.id).to eq tradable_seed.id.to_s }
  end
end
