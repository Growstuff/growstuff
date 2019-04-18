# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CropSearchService, type: :service do
  describe 'search', :elasticsearch do
    def search(term)
      CropSearchService.search(term).map(&:name)
    end

    context 'with some crops' do
      let!(:mushroom) { FactoryBot.create(:crop, name: 'mushroom') }
      let!(:tomato) { FactoryBot.create(:crop ,name: 'tomato') }
      let!(:taewa) { FactoryBot.create(:crop, name: 'taewa') }
      let!(:zucchini) { FactoryBot.create(:crop, name: 'zucchini') }
      let!(:broccoli) { FactoryBot.create(:crop, name: 'broccoli') }
      before do
        # Alternate name
        FactoryBot.create :alternate_name, name: 'fungus', crop: mushroom
        # scientific name
        FactoryBot.create :scientific_name, name: 'Agaricus bisporus', crop: mushroom

        # Requested and rejected
        FactoryBot.create(:rejected_crop, name: 'rejected mushroom')
        FactoryBot.create(:crop_request, name: 'requested mushroom')

        # Child record
        FactoryBot.create(:crop, name: 'portobello', parent: mushroom)
        Crop.reindex if ENV['GROWSTUFF_ELASTICSEARCH'] == 'true'
      end

      describe 'finds exact match' do
        it { expect(search('mushroom')).to eq ['mushroom'] }
      end

      describe 'finds approximate match "mush"' do
        it { expect(search('mush')).to eq ['mushroom'] }
      end

      if ENV['GROWSTUFF_ELASTICSEARCH'] == 'true'
        describe 'finds mispellings matches' do
          it { expect(search('muhsroom')).to eq ['mushroom'] }
          it { expect(search('mushrom')).to eq ['mushroom'] }
          it { expect(search('zuchini')).to eq ['zucchini'] }
          it { expect(search('brocoli')).to eq ['broccoli'] }
        end
      end

      describe 'doesn\'t find non-match "coffee"' do
        it { expect(search('coffee')).to eq [] }
      end

      if ENV['GROWSTUFF_ELASTICSEARCH'] == 'true'
        describe 'finds plurals' do
          it { expect(search('mushrooms')).to eq ['mushroom'] }
          it { expect(search('tomatoes')).to eq ['tomato'] }
        end
      end

      describe 'searches case insensitively' do
        it { expect(search('mUsHroom')).to eq ['mushroom'] }
        it { expect(search('Mushroom')).to eq ['mushroom'] }
        it { expect(search('MUSHROOM')).to eq ['mushroom'] }
      end

      it 'finds by alternate names' do
        expect(search('fungus')).to eq ['mushroom']
      end

      describe 'finds by scientific names' do
        it { expect(search('Agaricus bisporus')).to eq ['mushroom'] }
        it { expect(search('agaricus bisporus')).to eq ['mushroom'] }
        it { expect(search('Agaricus')).to eq ['mushroom'] }
        it { expect(search('bisporus')).to eq ['mushroom'] }
      end

      describe "doesn't find rejected crop" do
        it { expect(search('rejected')).to eq [] }
      end

      describe "doesn't find pending crop" do
        it { expect(search('requested')).to eq [] }
      end
    end
  end
end
