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
    expect(ideas.first.schedule.size).to eq 2
  end

  it 'keys the idea by template' do
    expect(ideas.first.key).to eq "template:#{template.id}"
  end

  it 'lists the jobs it would add' do
    expect(ideas.first.schedule.map { |entry| entry.step.name }).to eq %w(Stake Feed)
  end

  it 'gives the day of each job' do
    expect(ideas.first.schedule.map(&:date)).to eq [Date.new(2026, 11, 3), Date.new(2026, 11, 17)]
  end

  context 'with several plantings of the crop' do
    let!(:earlier) { create(:planting, owner: member, crop: planting.crop, planted_at: Date.new(2026, 10, 10)) }

    it 'has one idea for the template' do
      expect(ideas.size).to eq 1
    end

    it 'is for the latest planting' do
      expect(ideas.first.planting).to eq planting
    end

    it 'counts the jobs for that planting only' do
      expect(ideas.first.schedule.size).to eq 2
    end
  end

  context 'when the latest planting has no jobs left to add' do
    let!(:earlier) { create(:planting, owner: member, crop: planting.crop, planted_at: Date.new(2026, 10, 10)) }

    before { ApplyCropJobTemplate.new(template, planting, today:).call }

    it 'is for an earlier one' do
      expect(ideas.first.planting).to eq earlier
    end
  end

  context 'with a planting of a variety of the crop the template is for' do
    let(:variety) { create(:crop, parent: planting.crop) }
    let(:planting) { create(:planting, owner: member, planted_at: Date.new(2026, 10, 20)) }
    let!(:own) { create(:planting, owner: member, crop: variety, planted_at: Date.new(2026, 10, 21)) }

    it 'is for the variety\'s planting, the latest' do
      expect(ideas.first.planting).to eq own
    end

    it 'is still one idea for the template' do
      expect(ideas.size).to eq 1
    end

    it 'is about the crop the template is for' do
      expect(ideas.first.crop).to eq planting.crop
    end
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
