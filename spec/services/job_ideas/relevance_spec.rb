# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::Relevance do
  subject(:ranked) { described_class.new(member).rank(ideas) }

  let(:member) { create(:member) }
  let(:crop) { create(:crop, name: 'onion') }
  let(:other_crop) { create(:crop, name: 'lemon') }
  let(:plant) { JobIdeas::Idea.new(kind: :community, name: 'Plant onion', crop:) }
  let(:prune) { JobIdeas::Idea.new(kind: :world, name: 'Prune lemon', crop: other_crop) }
  let(:general) { JobIdeas::Idea.new(kind: :past_job, name: 'Clean tools') }
  let(:ideas) { [prune, general, plant] }

  context 'with current seeds' do
    before { create(:seed, owner: member, crop:) }

    it 'puts planting jobs first' do
      expect(ranked).to eq [plant, general, prune]
    end

    context 'with a sowing job' do
      let(:plant) { JobIdeas::Idea.new(kind: :community, name: 'Sow onion', crop:) }

      it 'puts sowing jobs first' do
        expect(ranked.first).to eq plant
      end
    end

    context 'with a past planting idea' do
      let(:plant) { JobIdeas::Idea.new(kind: :past_planting, name: crop.name, crop:) }

      it 'recognizes planting ideas without a verb' do
        expect(ranked.first).to eq plant
      end
    end

    context 'without a linked crop' do
      let(:plant) { JobIdeas::Idea.new(kind: :community, name: 'PLANT ONIONS') }

      it 'recognizes crop names and plurals without regard to case' do
        expect(ranked.first).to eq plant
      end
    end
  end

  context 'without current seeds' do
    before { create(:finished_seed, owner: member, crop:) }

    it 'keeps planting ideas but ranks them below general jobs' do
      expect(ranked).to eq [general, prune, plant]
    end
  end

  context 'with an active planting' do
    before { create(:planting, owner: member, crop: other_crop) }

    it 'keeps crop care jobs ahead of jobs for missing crops' do
      expect(ranked).to eq [prune, general, plant]
    end
  end

  context 'with a finished planting' do
    before { create(:planting, owner: member, crop: other_crop, finished: true) }

    it 'ranks crop care jobs below general jobs' do
      expect(ranked).to eq [general, prune, plant]
    end
  end

  context 'with seeds belonging to another member' do
    before { create(:seed, crop:) }

    it 'does not boost planting jobs' do
      expect(ranked).to eq [general, prune, plant]
    end
  end

  context 'with an unlinked crop care job' do
    let(:prune) { JobIdeas::Idea.new(kind: :world, name: 'Prune lemons') }

    before { other_crop }

    it 'penalizes jobs for crops the member is not growing' do
      expect(ranked).to eq [general, prune, plant]
    end
  end

  context 'with a crop name inside another word' do
    let(:plant) { JobIdeas::Idea.new(kind: :community, name: 'Plant onionweed') }

    before { crop }

    it 'does not treat part of a word as a crop' do
      expect(ranked).to eq [general, plant, prune]
    end
  end

  context 'with overlapping crop names' do
    let(:prune) { JobIdeas::Idea.new(kind: :world, name: 'Trim lemon grass') }
    let(:ideas) { [general, prune] }
    let(:grass) { create(:crop, name: 'lemon grass') }

    before do
      other_crop
      create(:planting, owner: member, crop: grass)
    end

    it 'uses the longest matching crop name' do
      expect(ranked).to eq [general, prune]
    end
  end

  context 'with a linked crop that differs from the name' do
    let(:plant) { JobIdeas::Idea.new(kind: :community, name: 'Plant lemon', crop:) }

    before { create(:seed, owner: member, crop:) }

    it 'uses the linked crop' do
      expect(ranked.first).to eq plant
    end
  end
end
