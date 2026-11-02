# frozen_string_literal: true

require 'rails_helper'

describe CropMerger do
  subject(:merger) { described_class.new(duplicate, target, member:) }

  let(:member) { create(:crop_wrangling_member) }
  let(:duplicate) { create(:crop, name: 'habanero') }
  let(:target) { create(:crop, name: 'habanero pepper') }

  describe '#merge!' do
    context 'with the same crop twice' do
      let(:target) { duplicate }

      it 'refuses' do
        expect { merger.merge! }.to raise_error(described_class::Error)
      end
    end

    context 'with two crops' do
      it 'deletes the duplicate' do
        merger.merge!
        expect(Crop.exists?(duplicate.id)).to be false
      end

      it 'keeps the target' do
        merger.merge!
        expect(Crop.exists?(target.id)).to be true
      end

      it 'returns the target' do
        expect(merger.merge!).to eq target
      end

      it "adds the duplicate's name to the target" do
        merger.merge!
        expect(target.alternate_names.pluck(:name)).to eq ['habanero']
      end

      it 'records the member as the creator of that name' do
        merger.merge!
        expect(target.alternate_names.first.creator).to eq member
      end
    end

    context 'with plantings' do
      let!(:planting) { create(:planting, crop: duplicate) }

      before { merger.merge! }

      it 'moves them to the target' do
        expect(planting.reload.crop).to eq target
      end

      it 'updates the target planting count' do
        expect(target.reload.plantings_count).to eq 1
      end
    end

    context 'with seeds' do
      let!(:seed) { create(:seed, crop: duplicate) }

      it 'moves them to the target' do
        merger.merge!
        expect(seed.reload.crop).to eq target
      end
    end

    context 'with harvests' do
      let!(:harvest) { create(:harvest, crop: duplicate) }

      before { merger.merge! }

      it 'moves them to the target' do
        expect(harvest.reload.crop).to eq target
      end

      it 'updates the target harvest count' do
        expect(target.reload.harvests_count).to eq 1
      end
    end

    context 'with a photo on a harvest' do
      let(:harvest) { create(:harvest, crop: duplicate) }

      before do
        harvest.photos << create(:photo, owner: harvest.owner)
        merger.merge!
      end

      it 'moves the photo to the target' do
        expect(target.photo_associations.count).to eq 1
      end
    end

    context 'with a post about the duplicate' do
      let(:post) { create(:post) }

      before do
        CropPost.create!(crop: duplicate, post:)
        merger.merge!
      end

      it 'moves the post to the target' do
        expect(target.posts).to eq [post]
      end
    end

    context 'with a post about both crops' do
      let(:post) { create(:post) }

      before do
        CropPost.create!(crop: duplicate, post:)
        CropPost.create!(crop: target, post:)
        merger.merge!
      end

      it 'does not list the post twice' do
        expect(CropPost.where(crop: target).count).to eq 1
      end
    end

    context 'with a job template' do
      let!(:template) { create(:crop_job_template, crop: duplicate) }

      it 'moves it to the target' do
        merger.merge!
        expect(template.reload.crop).to eq target
      end
    end

    context 'with a dismissal by a member who dismissed both' do
      let(:gardener) { create(:member) }

      before do
        create(:crop_dismissal, crop: duplicate, member: gardener)
        create(:crop_dismissal, crop: target, member: gardener)
        merger.merge!
      end

      it 'keeps one dismissal' do
        expect(CropDismissal.where(member: gardener).count).to eq 1
      end
    end

    context 'with a variety of the duplicate' do
      let!(:variety) { create(:crop, name: 'habanero orange', parent: duplicate) }

      it 'moves it under the target' do
        merger.merge!
        expect(variety.reload.parent).to eq target
      end
    end

    context 'when the target is a variety of the duplicate' do
      let(:grandparent) { create(:crop, name: 'capsicum') }
      let(:duplicate) { create(:crop, name: 'habanero', parent: grandparent) }
      let(:target) { create(:crop, name: 'habanero pepper', parent: duplicate) }

      before { merger.merge! }

      it 'moves the target up to the duplicate parent' do
        expect(target.reload.parent).to eq grandparent
      end
    end

    context 'when the target is deeper under the duplicate' do
      let(:middle) { create(:crop, name: 'hot pepper', parent: duplicate) }
      let(:target) { create(:crop, name: 'habanero pepper', parent: middle) }

      before do
        middle
        merger.merge!
      end

      it 'puts the target under no parent' do
        expect(target.reload.parent).to be_nil
      end

      it 'moves the in-between crop under the target' do
        expect(middle.reload.parent).to eq target
      end
    end

    context 'with scientific names' do
      before do
        create(:scientific_name, crop: duplicate, name: 'Capsicum chinense')
        create(:scientific_name, crop: duplicate, name: 'Capsicum annuum')
        create(:scientific_name, crop: target, name: 'capsicum chinense')
        merger.merge!
      end

      it 'keeps the names the target lacked, once each' do
        expect(target.scientific_names.map { |name| name.name.downcase }).to contain_exactly('capsicum chinense', 'capsicum annuum')
      end
    end

    context 'with an alternate name the target already has' do
      before do
        create(:alternate_name, crop: duplicate, name: 'Hot Pepper')
        create(:alternate_name, crop: target, name: 'hot pepper')
        merger.merge!
      end

      it 'does not copy it' do
        expect(target.alternate_names.map { |name| name.name.downcase }).to contain_exactly('hot pepper', 'habanero')
      end
    end

    context 'when the target already has the duplicate name as an alternate name' do
      before do
        create(:alternate_name, crop: target, name: 'Habanero')
        merger.merge!
      end

      it 'does not add it again' do
        expect(target.alternate_names.count).to eq 1
      end
    end

    context 'with companions' do
      let(:friend) { create(:crop, name: 'basil') }

      before do
        CropCompanion.create!(crop_a: duplicate, crop_b: friend)
        CropCompanion.create!(crop_a: friend, crop_b: duplicate)
        CropCompanion.create!(crop_a: duplicate, crop_b: target)
        merger.merge!
      end

      it 'moves them to the target without pairing the target with itself' do
        expect(CropCompanion.where(crop_a: target).or(CropCompanion.where(crop_b: target)).count).to eq 2
      end
    end

    context 'when the target has no description' do
      let(:duplicate) { create(:crop, name: 'habanero', description: 'A hot pepper.') }

      it 'takes the duplicate description' do
        merger.merge!
        expect(target.reload.description).to eq 'A hot pepper.'
      end
    end

    context 'when the target has a description' do
      let(:duplicate) { create(:crop, name: 'habanero', description: 'A hot pepper.') }
      let(:target) { create(:crop, name: 'habanero pepper', description: 'Fruity and fierce.') }

      it 'keeps it' do
        merger.merge!
        expect(target.reload.description).to eq 'Fruity and fierce.'
      end
    end
  end

  describe '#moves' do
    before do
      create(:planting, crop: duplicate)
      create(:planting, crop: duplicate)
    end

    it 'counts what would move' do
      expect(merger.moves).to include('Plantings' => 2)
    end
  end
end
