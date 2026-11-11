# frozen_string_literal: true

require 'rails_helper'

describe Feature do
  subject(:feature) { described_class.find(:job_ideas) }

  let(:member) { create(:member) }

  context 'with a member grant' do
    before { feature.enable_member(member) }

    it 'enables the feature for that member' do
      expect(described_class.enabled?(:job_ideas, member)).to be true
    end

    it 'leaves the global flag off' do
      expect(feature).not_to be_enabled
    end

    it 'leaves other members disabled' do
      expect(described_class.enabled?(:job_ideas, create(:member))).to be false
    end

    it 'lists the granted member' do
      expect(feature.members).to contain_exactly(member)
    end

    it 'preserves grants after switching the global flag on and off' do
      feature.enabled = true
      feature.enabled = false
      expect(described_class.enabled?(:job_ideas, member)).to be true
    end

    it 'removes a grant' do
      feature.disable_member(member)
      expect(described_class.enabled?(:job_ideas, member)).to be false
    end

    it 'keeps global access after removing a grant' do
      feature.enabled = true
      feature.disable_member(member)
      expect(described_class.enabled?(:job_ideas, member)).to be true
    end
  end
end
