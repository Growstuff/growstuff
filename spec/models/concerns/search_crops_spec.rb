# frozen_string_literal: true

require 'rails_helper'

describe SearchCrops do
  describe 'ACCENTED and PLAIN' do
    it 'have the same length, as translate() pairs them up' do
      expect(described_class::ACCENTED.length).to eq described_class::PLAIN.length
    end
  end

  describe '.normalise' do
    it 'folds accents and case' do
      expect(described_class.normalise('Jalapeño')).to eq 'jalapeno'
    end
  end

  describe 'database settings' do
    it 'uses the similarity threshold the queries are written for' do
      threshold = ActiveRecord::Base.connection.select_value('SHOW pg_trgm.word_similarity_threshold')
      expect(threshold.to_f).to eq described_class::MIN_SIMILARITY
    end
  end

  describe 'Crop.search_by_name' do
    subject(:names) { Crop.search_by_name(term).map(&:name) }

    let!(:jalapeno) { create(:crop, name: 'jalapeño') }
    let!(:cucumber) { create(:crop, name: 'cucumber') }
    let!(:eggplant) { create(:crop, name: 'eggplant') }

    before { create(:alternate_name, crop: eggplant, name: 'aubergine') }

    context 'with a term without the accent' do
      let(:term) { 'jalapeno' }

      it { is_expected.to eq ['jalapeño'] }
    end

    context 'with a term with the accent' do
      let(:term) { 'jalapeño' }

      it { is_expected.to eq ['jalapeño'] }
    end

    context 'with the start of a word' do
      let(:term) { 'cucum' }

      it { is_expected.to eq ['cucumber'] }
    end

    context 'with a typo' do
      let(:term) { 'cucmber' }

      it { is_expected.to eq ['cucumber'] }
    end

    context 'with an alternate name' do
      let(:term) { 'aubergine' }

      it { is_expected.to eq ['eggplant'] }
    end

    context 'with text unlike any name' do
      let(:term) { 'zzzzzz' }

      it { is_expected.to be_empty }
    end

    context 'with a blank term' do
      let(:term) { '' }

      it { is_expected.to match_array %w(jalapeño cucumber eggplant) }
    end
  end

  describe 'trigram indexes' do
    let(:term) { 'cucumber' }

    %w(crops alternate_names scientific_names).each do |table|
      it "serve the search of #{table}" do
        plan = ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute('SET LOCAL enable_seqscan = off')
          ActiveRecord::Base.connection.select_values("EXPLAIN #{Crop.search_by_name(term).to_sql}").join("\n")
        end
        expect(plan).to include "Bitmap Index Scan on index_#{table}_on_normalised_name"
      end
    end
  end
end
