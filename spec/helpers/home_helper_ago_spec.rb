# frozen_string_literal: true

require 'rails_helper'

# Plantings and harvests are dated, not timed, so "today" must not turn into
# "19 hours ago" for someone whose midnight was hours back.
describe HomeHelper do
  include ActiveSupport::Testing::TimeHelpers

  describe '#ago_in_words' do
    around { |example| travel_to(Time.zone.local(2026, 10, 12, 19, 30)) { example.run } }

    it 'says today for a date that is today' do
      expect(helper.ago_in_words(Date.current)).to eq 'today'
    end

    it 'says yesterday' do
      expect(helper.ago_in_words(Date.current - 1)).to eq 'yesterday'
    end

    it 'counts days for an older date' do
      expect(helper.ago_in_words(Date.current - 5)).to eq '5 days ago'
    end

    it 'still counts hours for a time' do
      expect(helper.ago_in_words(3.hours.ago)).to eq 'about 3 hours ago'
    end
  end
end
