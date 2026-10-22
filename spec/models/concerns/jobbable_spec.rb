# frozen_string_literal: true

require 'rails_helper'

describe Jobbable do
  shared_examples 'jobbable' do
    let(:job) { create(:job, jobbable: thing, owner: thing.try(:owner) || create(:member)) }

    it 'has the jobs about it' do
      expect(thing.reload.jobs).to eq [job]
    end

    it 'keeps the job, without the link, when it goes' do
      job
      thing.destroy
      expect(job.reload.jobbable).to be_nil
    end
  end

  describe Crop do
    it_behaves_like 'jobbable' do
      let(:thing) { create(:crop) }
    end
  end

  describe Planting do
    it_behaves_like 'jobbable' do
      let(:thing) { create(:planting) }
    end
  end

  describe Seed do
    it_behaves_like 'jobbable' do
      let(:thing) { create(:seed) }
    end
  end
end
