# frozen_string_literal: true

require 'rails_helper'

describe CropJobTemplateImporter do
  subject(:importer) { described_class.new(out: output) }

  let(:output) { StringIO.new }
  let!(:tomato) { create(:crop, name: 'tomato') }
  let(:step) { { 'name' => 'Stake the plants', 'amount' => 2, 'unit' => 'weeks', 'direction' => 'after', 'anchor' => 'planting_out' } }
  let(:template) { { 'name' => 'Growing tomatoes', 'season' => 'any', 'status' => 'draft', 'steps' => [step] } }
  let(:data) { { 'crop' => 'tomato', 'templates' => [template] } }

  describe '#import' do
    context 'with a crop and a template' do
      before { importer.import(data) }

      it 'creates the template for the crop' do
        expect(tomato.crop_job_templates.pluck(:name)).to eq ['Growing tomatoes']
      end

      it 'keeps the status it was given' do
        expect(tomato.crop_job_templates.first).to be_draft
      end

      it 'creates the steps' do
        expect(tomato.crop_job_templates.first.steps.first).to have_attributes(
          name: 'Stake the plants', offset_amount: 2, offset_unit: 'weeks', direction: 'after', anchor: 'planting_out', repeat: 'once'
        )
      end
    end

    context 'with several steps' do
      let(:template) { super().merge('steps' => %w(First Second Third).map { |name| step.merge('name' => name) }) }

      it 'keeps them in the order written' do
        importer.import(data)
        expect(tomato.crop_job_templates.first.steps.pluck(:name)).to eq %w(First Second Third)
      end
    end

    context 'with a step that gives only its name' do
      let(:template) { super().merge('steps' => [{ 'name' => 'Water' }]) }

      it 'uses the defaults for the rest' do
        importer.import(data)
        expect(tomato.crop_job_templates.first.steps.first).to have_attributes(
          offset_amount: 0, offset_unit: 'weeks', direction: 'after', anchor: 'planting_out', repeat: 'once'
        )
      end
    end

    context 'when the template is already there' do
      before do
        create(:crop_job_template, crop: tomato, name: 'Growing tomatoes', status: :published)
        importer.import(data)
      end

      it 'does not add another' do
        expect(tomato.crop_job_templates.count).to eq 1
      end

      it 'leaves what is there alone' do
        expect(tomato.crop_job_templates.first).to be_published
      end
    end

    context 'when run twice' do
      it 'creates it once' do
        2.times { importer.import(data) }
        expect(CropJobTemplate.count).to eq 1
      end
    end

    context 'with a template for a variety' do
      let!(:cherry) { create(:crop, name: 'cherry tomato', parent: tomato) }
      let(:template) { super().merge('applies_to' => 'cherry tomato') }

      it 'is for that variety' do
        importer.import(data)
        expect(cherry.crop_job_templates.count).to eq 1
      end

      it 'is not for the crop' do
        importer.import(data)
        expect(tomato.crop_job_templates.count).to eq 0
      end
    end

    context 'with a variety the crop does not have' do
      let(:template) { super().merge('applies_to' => 'purple tomato') }

      it 'skips the template' do
        importer.import(data)
        expect(CropJobTemplate.count).to eq 0
      end

      it 'says so' do
        importer.import(data)
        expect(output.string).to include('no variety called "purple tomato"')
      end
    end

    context 'with a crop that is not here' do
      let(:data) { { 'crop' => 'dragonfruit', 'templates' => [template] } }

      it 'skips the templates' do
        importer.import(data)
        expect(CropJobTemplate.count).to eq 0
      end

      it 'says so' do
        importer.import(data)
        expect(output.string).to include('no crop called "dragonfruit"')
      end
    end

    context 'with a setting that is not allowed' do
      let(:template) { super().merge('steps' => [step.merge('unit' => 'fortnights')]) }

      it 'says which template, and what is wrong' do
        expect { importer.import(data, source: 'tomato.json') }.to raise_error(described_class::Invalid, /tomato.json.*Growing tomatoes/)
      end

      it 'creates nothing' do
        begin
          importer.import(data)
        rescue described_class::Invalid
          nil
        end
        expect(CropJobTemplate.count).to eq 0
      end
    end
  end

  describe '#import_files' do
    it 'counts what it created, found and skipped' do
      path = Rails.root.join('tmp/crop_job_templates_spec.json')
      File.write(path, JSON.generate(data))
      expect(importer.import_files([path, path])).to eq(created: 1, existing: 1)
    ensure
      FileUtils.rm_f(path)
    end
  end

  describe 'the seed files' do
    Rails.root.glob('db/seeds/crop_job_templates/*.json').each do |path|
      it "#{path.basename} is valid" do
        create(:crop, name: JSON.parse(path.read)['crop'])
        expect { described_class.new(out: output).import_file(path) }.not_to raise_error
      end
    end
  end
end
