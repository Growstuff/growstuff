# frozen_string_literal: true

require 'rails_helper'

describe PhotoAssociation do
  subject(:association) { job.photo_associations.build(photo:) }

  let(:job) { create(:job) }
  let(:photo) { create(:photo, owner: job.owner) }

  it { is_expected.to be_valid }

  it 'has no moment, unless it is given one' do
    expect(association.moment).to be_nil
  end

  describe 'moment' do
    it 'can be before' do
      association.moment = 'before'
      expect(association).to be_valid
    end

    it 'can be after' do
      association.moment = 'after'
      expect(association).to be_valid
    end

    it 'cannot be anything else' do
      association.moment = 'during'
      expect(association).not_to be_valid
    end

    it 'is none when left empty' do
      association.moment = ''
      expect(association.moment).to be_nil
    end
  end

  context 'when the photo is someone else\'s' do
    let(:photo) { create(:photo) }

    it { is_expected.not_to be_valid }
  end
end
