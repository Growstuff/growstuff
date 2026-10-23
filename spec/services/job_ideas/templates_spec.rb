# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::Templates do
  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:member) }
  let(:planting) { create(:planting, owner: member, planted_at: Date.new(2026, 10, 20)) }
  let(:status) { 'published' }
  let!(:template) { create(:crop_job_template, crop: planting.crop, status:) }

  before do
    create(:crop_job_step, crop_job_template: template, name: 'Stake', offset_amount: 2, offset_unit: 'weeks')
    create(:crop_job_step, crop_job_template: template, name: 'Feed', offset_amount: 4, offset_unit: 'weeks')
  end

  it 'has an idea for the template' do
    expect(ideas.map(&:template)).to eq [template]
  end

  it 'is about the planting' do
    expect(ideas.first.planting).to eq planting
  end

  it 'counts the jobs it would add' do
    expect(ideas.first.job_count).to eq 2
  end

  it 'keys the idea by template and planting' do
    expect(ideas.first.key).to eq "template:#{template.id}:#{planting.id}"
  end

  context 'with a draft template' do
    let(:status) { 'draft' }

    it { is_expected.to be_empty }
  end

  context 'when someone else grows the crop' do
    let(:planting) { create(:planting, planted_at: Date.new(2026, 10, 20)) }

    it { is_expected.to be_empty }
  end

  context 'when every step has been added' do
    before { ApplyCropJobTemplate.new(template, planting, today:).call }

    it { is_expected.to be_empty }
  end

  context 'when the planting is finished' do
    let(:planting) { create(:planting, owner: member, planted_at: Date.new(2026, 10, 20), finished: true) }

    it { is_expected.to be_empty }
  end
end
