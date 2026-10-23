# frozen_string_literal: true

require 'rails_helper'

describe JobIdeaDismissal do
  include ActiveSupport::Testing::TimeHelpers

  describe '.hiding' do
    subject(:hiding) { described_class.hiding }

    it 'has a dismissal from this week' do
      expect(hiding).to include(create(:job_idea_dismissal))
    end

    it 'leaves out one from over a month ago' do
      dismissal = create(:job_idea_dismissal)
      travel_to(2.months.from_now) { expect(described_class.hiding).not_to include(dismissal) }
    end
  end

  describe '.dismiss!' do
    let(:member) { create(:member) }

    it 'hides the idea' do
      described_class.dismiss!(member, 'last_year:snip:1')
      expect(member.job_idea_dismissals.hiding.pluck(:key)).to eq ['last_year:snip:1']
    end

    context 'when it was dismissed before' do
      before do
        travel_to(2.months.ago) { described_class.dismiss!(member, 'last_year:snip:1') }
        described_class.dismiss!(member, 'last_year:snip:1')
      end

      it 'hides it again' do
        expect(member.job_idea_dismissals.hiding.count).to eq 1
      end

      it 'does not keep two' do
        expect(member.job_idea_dismissals.count).to eq 1
      end
    end
  end
end
