# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Problem, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      problem = build(:problem)
      expect(problem).to be_valid
    end

    it 'is invalid without a title' do
      problem = build(:problem, title: nil)
      expect(problem).not_to be_valid
      expect(problem.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without a problem_type' do
      problem = build(:problem, problem_type: nil)
      expect(problem).not_to be_valid
      expect(problem.errors[:problem_type]).to include("can't be blank")
    end

    it 'is invalid with an unknown problem_type' do
      problem = build(:problem, problem_type: 'InvalidType')
      expect(problem).not_to be_valid
      expect(problem.errors[:problem_type]).to include("is not included in the list")
    end

    it 'allows Disease, Pest, and General problem types' do
      %w(Disease Pest General).each do |type|
        problem = build(:problem, problem_type: type)
        expect(problem).to be_valid
      end
    end
  end

  describe 'associations' do
    let(:problem) { create(:problem) }

    it 'can have scientific names' do
      sciname = problem.scientific_names.create!(name: 'Phytophthora infestans', gbif_key: 3203584, wikidata_id: 'Q152917')
      expect(problem.scientific_names).to include(sciname)
      expect(sciname.gbif_id).to eq(3203584)
    end

    it 'can have alternate names' do
      altname = problem.alternate_names.create!(name: 'Late Blight', language: 'EN')
      expect(problem.alternate_names).to include(altname)
    end

    it 'destroys associated scientific and alternate names when destroyed' do
      problem.scientific_names.create!(name: 'Test Sci Name')
      problem.alternate_names.create!(name: 'Test Alt Name')

      expect { problem.destroy }.to change(ScientificName, :count).by(-1).and change(AlternateName, :count).by(-1)
    end
  end
end
