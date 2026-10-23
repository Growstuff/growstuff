# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::Add do
  subject(:added) { described_class.new(member, idea, today: Date.new(2026, 10, 23)).call }

  let(:member) { create(:member) }
  let(:crop) { create(:crop, name: 'tomato') }
  let(:planting) { create(:planting, owner: member, crop:, planted_at: Date.new(2026, 10, 20)) }
  let(:idea) { JobIdeas::Idea.new(kind:, crop:, planting:, name: 'Mound up', template:, key: 'template:1') }
  let(:template) { nil }

  context 'with a harvest' do
    let(:kind) { :harvest }

    it 'makes a job to harvest the crop' do
      expect(added.map(&:name)).to eq ['Harvest tomato']
    end

    it 'remembers the job is to harvest' do
      expect(added.first).to be_action_harvest
    end

    it 'makes it about the planting' do
      expect(added.first.jobbable).to eq planting
    end

    it 'puts it in the planting\'s garden' do
      expect(added.first.garden).to eq planting.garden
    end

    it 'gives it no day' do
      expect(added.first.due_date).to be_nil
    end
  end

  context 'with a template' do
    let(:kind) { :template }
    let(:template) { create(:crop_job_template, crop:) }

    before { create(:crop_job_step, crop_job_template: template, name: 'Stake', offset_amount: 2) }

    it 'makes the jobs from its steps' do
      expect(added.map(&:name)).to eq ['Stake']
    end

    it 'puts the idea away so it does not come back for another planting' do
      added
      expect(member.job_idea_dismissals.hiding.pluck(:key)).to eq [idea.key]
    end
  end

  context 'with a job from other gardeners' do
    let(:kind) { :community }

    it 'makes a job of the same name about the crop' do
      expect(added.first).to have_attributes(name: 'Mound up', jobbable: crop, action: nil)
    end
  end
end
