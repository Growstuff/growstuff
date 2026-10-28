# frozen_string_literal: true

require 'rails_helper'

describe PhotoAssociation do
  subject(:association) { job.photo_associations.build(photo:) }

  let(:job) { create(:job) }
  let(:photo) { create(:photo, owner: job.owner) }

  it { is_expected.to be_valid }

  it 'has no label, unless it is given one' do
    expect(association.label).to be_nil
  end

  describe 'label' do
    subject(:association) { item.photo_associations.build(photo: create(:photo, owner: item.owner), label:) }

    context 'with before, on a job' do
      let(:item) { job }
      let(:label) { 'before' }

      it { is_expected.to be_valid }
    end

    context 'with after, on a job' do
      let(:item) { job }
      let(:label) { 'after' }

      it { is_expected.to be_valid }
    end

    context 'with front, on a job' do
      let(:item) { job }
      let(:label) { 'front' }

      it { is_expected.not_to be_valid }
    end

    context 'with front, on a seed' do
      let(:item) { create(:seed) }
      let(:label) { 'front' }

      it { is_expected.to be_valid }
    end

    context 'with back, on a seed' do
      let(:item) { create(:seed) }
      let(:label) { 'back' }

      it { is_expected.to be_valid }
    end

    context 'with before, on a seed' do
      let(:item) { create(:seed) }
      let(:label) { 'before' }

      it { is_expected.not_to be_valid }
    end

    context 'with an empty string' do
      let(:item) { job }
      let(:label) { '' }

      it('is none') { expect(association.label).to be_nil }
    end

    context 'with any label, on a harvest' do
      let(:item) { create(:harvest) }
      let(:label) { 'front' }

      it { is_expected.not_to be_valid }
    end
  end

  describe 'a seed packet label' do
    let(:seed) { create(:seed) }
    let(:photo) { create(:photo, owner: seed.owner) }
    let(:association) { seed.photo_associations.build(photo:, label: 'front') }

    context 'when the seed already has a photo of that side' do
      let!(:earlier) { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: 'front') }

      before { association.save! }

      it('takes the label from the earlier photo') { expect(earlier.reload.label).to be_nil }
      it('keeps the label on the new photo') { expect(association.reload.label).to eq 'front' }
    end

    context 'when the seed has a photo of the other side' do
      let!(:other) { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: 'back') }

      before { association.save! }

      it('leaves it alone') { expect(other.reload.label).to eq 'back' }
    end
  end

  context 'when the photo is someone else\'s' do
    let(:photo) { create(:photo) }

    it { is_expected.not_to be_valid }
  end
end
