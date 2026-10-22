# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Activity do
  describe 'active scope' do
    it 'returns activities that are not finished' do
      active_activity = create(:activity, finished: false)
      finished_activity = create(:activity, finished: true)

      expect(described_class.active).to include(active_activity)
      expect(described_class.active).not_to include(finished_activity)
    end

    it 'treats nil finished as active' do
      activity = create(:activity, finished: nil)
      expect(described_class.active).to include(activity)
    end
  end
end
