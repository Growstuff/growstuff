# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CropSearchService, type: :service do
  describe 'search' do
    def search(term)
      CropSearchService.search(term).map(&:name)
    end

    context 'with some crops' do
      let!(:mushroom) { FactoryBot.create(:crop, name: 'mushroom') }
      let!(:tomato)   { FactoryBot.create(:crop, name: 'tomato') }
      let!(:taewa)    { FactoryBot.create(:crop, name: 'taewa') }
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
        Crop.reindex
      end

      describe 'finds exact match' do
        it { expect(search('mushroom')).to eq ['mushroom'] }
      end

      describe 'finds approximate match "mush"' do
        it { expect(search('mush')).to eq ['mushroom'] }
      end

      describe 'finds mispellings matches' do
        it { expect(search('muhsroom')).to eq ['mushroom'] }
        it { expect(search('mushrom')).to eq ['mushroom'] }
        it { expect(search('zuchini')).to eq ['zucchini'] }
        it { expect(search('brocoli')).to eq ['broccoli'] }
      end

      describe 'biased' do
        # Make some crops with planting counts
        let!(:mushroom_parent) { FactoryBot.create :crop, name: 'mushroom' }
        let!(:oyster)  { FactoryBot.create :crop, name: 'oyster mushroom', parent: mushroom_parent }
        let!(:shitake) { FactoryBot.create :crop, name: 'shitake mushroom', parent: mushroom_parent }
        let!(:common)  { FactoryBot.create :crop, name: 'common mushroom', parent: mushroom_parent }
        let!(:brown)   { FactoryBot.create :crop, name: 'brown mushroom', parent: mushroom_parent }
        let!(:white)   { FactoryBot.create :crop, name: 'white mushroom', parent: mushroom_parent }

        describe 'biased to higher planting counts' do
          subject { search('mushroom') }
          before do
            # Having plantings should bring these crops to the top of the search results
            FactoryBot.create_list :planting, 10, crop: white
            FactoryBot.create_list :planting, 4, crop: shitake
            Crop.reindex
          end
          it { expect(subject.first).to eq 'white mushroom' }
          it { expect(subject.second).to eq 'shitake mushroom' }
        end
        describe "biased to crops you've planted" do
          subject { described_class.search('mushroom', current_member: owner).map(&:name) }
          let(:owner) { FactoryBot.create :member }
          before do
            FactoryBot.create_list :planting, 10, crop: brown
            FactoryBot.create :planting, crop: oyster, owner: owner
            FactoryBot.create :planting, crop: oyster, owner: owner
            FactoryBot.create :planting, crop: shitake, owner: owner
            Crop.reindex
          end
          it { expect(subject.first).to eq oyster.name }
          it { expect(subject.second).to eq shitake.name }
        end
      end

      describe 'doesn\'t find non-match "coffee"' do
        it { expect(search('coffee')).to eq [] }
      end

      describe 'finds plurals' do
        it { expect(search('mushrooms')).to eq ['mushroom'] }
        it { expect(search('tomatoes')).to eq ['tomato'] }
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
