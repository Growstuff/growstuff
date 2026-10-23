# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas do
  subject(:ideas) { described_class.new(member, today:).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:member) }

  before { create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.new(2025, 10, 28)) }

  it 'has the ideas from each source' do
    expect(ideas.map(&:kind)).to eq [:last_year]
  end

  context 'when the member said it is not for them' do
    before { create(:job_idea_dismissal, member:, key: 'last_year:snip off scapes:') }

    it { is_expected.to be_empty }
  end

  context 'when that was over a month ago' do
    before { create(:job_idea_dismissal, member:, key: 'last_year:snip off scapes:', updated_at: 2.months.ago) }

    it 'has the idea again' do
      expect(ideas.size).to eq 1
    end
  end
end
