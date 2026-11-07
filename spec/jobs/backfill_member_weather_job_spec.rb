# frozen_string_literal: true

require 'rails_helper'

describe BackfillMemberWeatherJob do
  subject(:perform) { described_class.perform_now(member.id) }

  let(:member) { create(:member) }
  let(:updater) { instance_double(WeatherUpdater, update_member: 0) }

  before do
    allow(Feature).to receive(:enabled?).with(:planting_weather).and_return(true)
    allow(WeatherUpdater).to receive(:new).and_return(updater)
  end

  it 'fetches weather for the member' do
    expect(updater).to receive(:update_member).with(member)
    perform
  end

  context 'without the weather feature' do
    before { allow(Feature).to receive(:enabled?).with(:planting_weather).and_return(false) }

    it 'does not fetch weather' do
      expect(updater).not_to receive(:update_member)
      perform
    end
  end

  context 'when the member no longer exists' do
    it 'does not fetch weather' do
      expect(updater).not_to receive(:update_member)
      described_class.perform_now(-1)
    end
  end
end
