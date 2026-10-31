# frozen_string_literal: true

require 'rails_helper'

describe ReminderEvent do
  let(:member) { create(:member) }
  let(:today) { Date.new(2026, 10, 28) } # a Wednesday; its week starts on 26 October

  describe 'validations' do
    it { expect(described_class.new(member:, kind: 'planting_reminder', event: 'sent', created_at: Time.zone.now)).to be_valid }
    it { expect(described_class.new(member:, kind: 'other', event: 'sent', created_at: Time.zone.now)).not_to be_valid }
    it { expect(described_class.new(member:, kind: 'planting_reminder', event: 'opened', created_at: Time.zone.now)).not_to be_valid }
  end

  describe '.weekly' do
    def event(kind, event, created_at)
      create(:reminder_event, member:, kind:, event:, created_at:)
    end

    it 'counts sends in the week they were sent' do
      2.times { event('planting_reminder', 'sent', Time.zone.local(2026, 10, 27, 9)) }
      expect(described_class.weekly('planting_reminder', today:)[Date.new(2026, 10, 26)]).to eq('sent' => 2, 'unsubscribed' => 0)
    end

    it 'counts unsubscribes separately' do
      event('planting_reminder', 'unsubscribed', Time.zone.local(2026, 10, 28, 9))
      expect(described_class.weekly('planting_reminder', today:)[Date.new(2026, 10, 26)]).to eq('sent' => 0, 'unsubscribed' => 1)
    end

    it 'groups by week in UTC, whatever the time zone of the viewer' do
      # 00:30 on Monday 26 October in Auckland is still Sunday 25 October in UTC, so it belongs to the week before.
      Time.use_zone('Auckland') do
        event('planting_reminder', 'sent', Time.zone.local(2026, 10, 26, 0, 30))
        counts = described_class.weekly('planting_reminder', today:)
        expect([counts[Date.new(2026, 10, 19)]['sent'], counts[Date.new(2026, 10, 26)]['sent']]).to eq [1, 0]
      end
    end

    it 'leaves out other reminders' do
      event('harvest_reminder', 'sent', Time.zone.local(2026, 10, 27, 9))
      expect(described_class.weekly('planting_reminder', today:)[Date.new(2026, 10, 26)]).to eq('sent' => 0, 'unsubscribed' => 0)
    end

    it 'goes back the number of weeks asked for, newest first' do
      weeks = described_class.weekly('planting_reminder', weeks: 3, today:).keys
      expect(weeks).to eq [Date.new(2026, 10, 26), Date.new(2026, 10, 19), Date.new(2026, 10, 12)]
    end

    it 'leaves out events from before those weeks' do
      event('planting_reminder', 'sent', Time.zone.local(2026, 10, 11, 9))
      expect(described_class.weekly('planting_reminder', weeks: 3, today:).values.sum { |counts| counts['sent'] }).to eq 0
    end
  end
end
