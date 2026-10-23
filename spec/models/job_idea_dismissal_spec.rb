# frozen_string_literal: true

require 'rails_helper'

describe JobIdeaDismissal do
  include ActiveSupport::Testing::TimeHelpers

  let(:member) { create(:member) }
  let(:key) { 'past_job:snip:1' }

  def hidden_keys
    member.job_idea_dismissals.hiding.pluck(:key)
  end

  describe '.hiding' do
    subject(:hiding) { described_class.hiding }

    it 'has a dismissal still hidden' do
      expect(hiding).to include(create(:job_idea_dismissal, hidden_until: 1.day.from_now))
    end

    it 'leaves out one whose time has passed' do
      expect(hiding).not_to include(create(:job_idea_dismissal, hidden_until: 1.day.ago))
    end
  end

  describe '.dismiss!' do
    before { described_class.dismiss!(member, key) }

    it 'hides the idea' do
      expect(hidden_keys).to eq [key]
    end

    it 'still hides it in a month' do
      travel_to(2.months.from_now) { expect(hidden_keys).to eq [key] }
    end

    it 'lets it come back after a year' do
      travel_to(13.months.from_now) { expect(hidden_keys).to be_empty }
    end
  end

  describe '.snooze!' do
    before { described_class.snooze!(member, key, 'week') }

    it 'hides the idea' do
      expect(hidden_keys).to eq [key]
    end

    it 'lets it come back after the week' do
      travel_to(8.days.from_now) { expect(hidden_keys).to be_empty }
    end

    it 'snoozes for a month' do
      described_class.snooze!(member, key, 'month')
      travel_to(2.weeks.from_now) { expect(hidden_keys).to eq [key] }
    end

    it 'does not take a length it does not offer' do
      expect { described_class.snooze!(member, key, 'decade') }.to raise_error(KeyError)
    end

    it 'does not keep two for the same idea' do
      described_class.dismiss!(member, key)
      expect(member.job_idea_dismissals.count).to eq 1
    end
  end
end
