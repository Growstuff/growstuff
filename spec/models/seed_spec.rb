# frozen_string_literal: true

require 'rails_helper'

describe Seed do
  let(:owner) { FactoryBot.create :owner, login_name: 'tamateapokaiwhenua' }
  let(:seed)  { FactoryBot.build(:seed, owner: owner)                      }

  it 'saves a basic seed' do
    seed.save.should be(true)
  end

  it "has a slug" do
    seed.save
    seed.slug.should match(/tamateapokaiwhenua-magic-bean/)
  end

  context 'quantity' do
    it 'allows integer quantities' do
      @seed = FactoryBot.build(:seed, quantity: 99)
      @seed.should be_valid
    end

    it "doesn't allow decimal quantities" do
      @seed = FactoryBot.build(:seed, quantity: 99.9)
      @seed.should_not be_valid
    end

    it "doesn't allow non-numeric quantities" do
      @seed = FactoryBot.build(:seed, quantity: 'foo')
      @seed.should_not be_valid
    end

    it "allows blank quantities" do
      @seed = FactoryBot.build(:seed, quantity: nil)
      @seed.should be_valid
      @seed = FactoryBot.build(:seed, quantity: '')
      @seed.should be_valid
    end
  end

  context 'tradable' do
    it 'all valid tradable_to values should work' do
      %w(nowhere locally nationally internationally).each do |t|
        @seed = FactoryBot.build(:seed, tradable_to: t)
        @seed.should be_valid
      end
    end

    it 'refuses invalid tradable_to values' do
      @seed = FactoryBot.build(:seed, tradable_to: 'not valid')
      @seed.should_not be_valid
      @seed.errors[:tradable_to].should include(
        "You may only trade seed nowhere, locally, "\
        "nationally, or internationally"
      )
    end

    it 'does not allow nil or blank values' do
      @seed = FactoryBot.build(:seed, tradable_to: nil)
      @seed.should_not be_valid
      @seed = FactoryBot.build(:seed, tradable_to: '')
      @seed.should_not be_valid
    end

    it 'tradable gives the right answers' do
      @seed = FactoryBot.create(:seed, tradable_to: 'nowhere')
      @seed.tradable.should eq false
      @seed = FactoryBot.create(:seed, tradable_to: 'locally')
      @seed.tradable.should eq true
      @seed = FactoryBot.create(:seed, tradable_to: 'nationally')
      @seed.tradable.should eq true
      @seed = FactoryBot.create(:seed, tradable_to: 'internationally')
      @seed.tradable.should eq true
    end

    it 'recognises a tradable seed' do
      FactoryBot.create(:tradable_seed).tradable.should == true
    end

    it 'recognises an untradable seed' do
      FactoryBot.create(:untradable_seed).tradable.should == false
    end

    it 'scopes correctly' do
      @tradable = FactoryBot.create(:tradable_seed)
      @untradable = FactoryBot.create(:untradable_seed)
      described_class.tradable.should include @tradable
      described_class.tradable.should_not include @untradable
    end
  end

  context 'organic, gmo, heirloom' do
    it 'all valid organic values should work' do
      ['certified organic', 'non-certified organic',
       'conventional/non-organic', 'unknown'].each do |t|
        @seed = FactoryBot.build(:seed, organic: t)
        @seed.should be_valid
      end
    end

    it 'all valid GMO values should work' do
      ['certified GMO-free', 'non-certified GMO-free',
       'GMO', 'unknown'].each do |t|
        @seed = FactoryBot.build(:seed, gmo: t)
        @seed.should be_valid
      end
    end

    it 'all valid heirloom values should work' do
      %w(heirloom hybrid unknown).each do |t|
        @seed = FactoryBot.build(:seed, heirloom: t)
        @seed.should be_valid
      end
    end

    it 'refuses invalid organic/GMO/heirloom values' do
      %i(organic gmo heirloom).each do |field|
        @seed = FactoryBot.build(:seed, field => 'not valid')
        @seed.should_not be_valid
        @seed.errors[field].should_not be_empty
      end
    end

    it 'does not allow nil or blank values' do
      %i(organic gmo heirloom).each do |field|
        @seed = FactoryBot.build(:seed, field => nil)
        @seed.should_not be_valid
        @seed = FactoryBot.build(:seed, field => '')
        @seed.should_not be_valid
      end
    end
  end

  context 'interesting' do
    it 'lists interesting seeds' do
      # to be interesting a seed must:
      # 1) be tradable
      # 2) the owner must have a location set

      @located_member = FactoryBot.create(:london_member)
      @seed1 = FactoryBot.create(:tradable_seed, owner: @located_member)
      @seed2 = FactoryBot.create(:seed, owner: @located_member)
      @seed3 = FactoryBot.create(:tradable_seed)
      @seed4 = FactoryBot.create(:seed)

      described_class.interesting.should include @seed1
      described_class.interesting.should_not include @seed2
      described_class.interesting.should_not include @seed3
      described_class.interesting.should_not include @seed4
      described_class.interesting.size.should == 1
    end
  end

  context 'photos' do
    let(:seed) { FactoryBot.create :seed }

    before { seed.photos << FactoryBot.create(:photo, owner: seed.owner) }

    it 'is found in has_photos scope' do
      described_class.has_photos.should include(seed)
    end
  end

  context 'ancestry' do
    let(:parent_planting) { FactoryBot.create :planting                                                             }
    let(:seed)            { FactoryBot.create :seed, parent_planting: parent_planting, owner: parent_planting.owner }

    it "seed has a parent planting" do
      expect(seed.parent_planting).to eq(parent_planting)
    end
    it "planting has a child seed" do
      expect(parent_planting.child_seeds).to eq [seed]
    end
  end

  context "finished" do
    describe 'has finished fields' do
      let(:seed) { FactoryBot.create(:finished_seed) }

      it { expect(seed.finished).to eq true }
      it { expect(seed.finished_at).to be_an_instance_of Date }
    end

    describe 'scopes' do
      let!(:seed)          { FactoryBot.create(:seed)          }
      let!(:finished_seed) { FactoryBot.create(:finished_seed) }

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
    let!(:tradable_seed) { FactoryBot.create :tradable_seed, :reindex, finished: false  }
    let!(:finished_seed)   { FactoryBot.create :tradable_seed, :reindex, finished: true }
    let!(:untradable_seed) { FactoryBot.create :untradable_seed, :reindex               }

    before { described_class.reindex }
    subject { described_class.homepage_records(100) }

    it { expect(subject.count).to eq 1 }
    it { expect(subject.first.id).to eq tradable_seed.id.to_s }
  end
end
