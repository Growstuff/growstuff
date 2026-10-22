# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Job do
  describe 'active scope' do
    it 'returns jobs that are not finished' do
      active_job = create(:job, finished: false)
      finished_job = create(:job, finished: true)

      expect(described_class.active).to include(active_job)
      expect(described_class.active).not_to include(finished_job)
    end

    it 'treats nil finished as active' do
      job = create(:job, finished: nil)
      expect(described_class.active).to include(job)
    end
  end
end
