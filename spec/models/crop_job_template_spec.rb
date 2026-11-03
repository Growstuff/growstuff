# frozen_string_literal: true

require 'rails_helper'

describe CropJobTemplate do
  subject(:template) { build(:crop_job_template) }

  it { is_expected.to be_valid }

  it 'needs a name' do
    template.name = nil
    expect(template).not_to be_valid
  end

  it 'starts as a draft' do
    expect(template).to be_draft
  end

  it 'is offered in any season' do
    expect(template).to be_season_any
  end

  it 'rejects an unknown season' do
    template.season = 'monsoon'
    expect(template).not_to be_valid
  end

  it 'goes when its crop does' do
    template.save!
    expect { template.crop.destroy }.to change(described_class, :count).by(-1)
  end

  describe '#steps' do
    let(:template) { create(:crop_job_template) }
    let!(:second) { create(:crop_job_step, crop_job_template: template, position: 2) }
    let!(:first) { create(:crop_job_step, crop_job_template: template, position: 1) }

    it 'are in position order' do
      expect(template.steps).to eq [first, second]
    end

    it 'go when the template does' do
      expect { template.destroy }.to change(CropJobStep, :count).by(-2)
    end
  end

  describe '.for_crop' do
    subject(:found) { described_class.for_crop(crop) }

    let(:parent) { create(:crop) }
    let(:crop) { create(:crop, parent:) }

    it 'has templates written for the crop' do
      expect(found).to include(create(:crop_job_template, crop:))
    end

    it 'has templates written for its parent' do
      expect(found).to include(create(:crop_job_template, crop: parent))
    end

    it 'leaves out templates for other crops' do
      expect(found).not_to include(create(:crop_job_template))
    end

    it 'leaves out templates for a sibling variety' do
      expect(found).not_to include(create(:crop_job_template, crop: create(:crop, parent:)))
    end
  end

  describe '#season_months' do
    subject(:template) { build(:crop_job_template, season:) }

    let(:southern) { -41.3 }
    let(:northern) { 51.5 }

    context 'when it is for spring and summer' do
      let(:season) { 'spring_summer' }

      it { expect(template.season_months(southern)).to eq [1, 2, 9, 10, 11, 12] }
      it { expect(template.season_months(northern)).to eq [3, 4, 5, 6, 7, 8] }
      it { expect(template.season_months(nil)).to be_nil }
    end

    context 'when it is for autumn and winter' do
      let(:season) { 'autumn_winter' }

      it { expect(template.season_months(southern)).to eq [3, 4, 5, 6, 7, 8] }
    end

    context 'when it is for any time' do
      let(:season) { 'any' }

      it { expect(template.season_months(southern)).to be_nil }
    end
  end
end
