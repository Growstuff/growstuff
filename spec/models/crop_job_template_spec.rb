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
end
