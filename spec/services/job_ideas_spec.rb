# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas do
  subject(:ideas) { described_class.new(member, today:).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:member) }

  before { create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.new(2025, 10, 28)) }

  it 'has the ideas from each source' do
    create(:planting, owner: member, crop: create(:crop, perennial: false), planted_at: Date.new(2025, 10, 28))
    expect(ideas.map(&:kind)).to match_array(%i(past_job past_planting))
  end

  context 'when the member said it is not for them' do
    before { create(:job_idea_dismissal, member:, key: 'past_job:snip off scapes:') }

    it { is_expected.to be_empty }
  end

  context 'when the time it was hidden for has passed' do
    before { create(:job_idea_dismissal, member:, key: 'past_job:snip off scapes:', hidden_until: 1.day.ago) }

    it 'has the idea again' do
      expect(ideas.size).to eq 1
    end
  end

  describe '#shown' do
    let(:ideas) { described_class.new(member, today:) }

    before do
      7.times { |i| create(:job, :finished_without_time, owner: member, name: "Job #{i}", due_date: Date.new(2025, 10, 28)) }
    end

    it 'is a few ideas' do
      expect(ideas.shown.size).to eq described_class::SHOWN
    end

    it 'says how many more there are' do
      expect(ideas.more).to eq 3
    end

    it 'brings the next when one is dismissed' do
      create(:job_idea_dismissal, member:, key: ideas.shown.first.key)
      expect(described_class.new(member, today:).shown.map(&:key)).to include(ideas.ideas[described_class::SHOWN].key)
    end

    it 'takes the sources in turn' do
      create(:planting, owner: member, crop: create(:crop, perennial: false), planted_at: Date.new(2025, 10, 28))
      expect(described_class.new(member, today:).shown.map(&:kind).first(2)).to eq %i(past_job past_planting)
    end
  end
end
