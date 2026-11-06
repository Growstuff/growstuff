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
    let!(:earlier) { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: 'front') }
    let(:later) { seed.photo_associations.create!(photo: create(:photo, owner: seed.owner), label: 'front') }

    it('is kept by the earlier photo when the side is photographed again') do
      later
      expect(earlier.reload.label).to eq 'front'
    end

    it('is on the later photo too') { expect(later.reload.label).to eq 'front' }
  end

  context 'when the photo is someone else\'s' do
    let(:photo) { create(:photo) }

    it { is_expected.not_to be_valid }
  end
end
