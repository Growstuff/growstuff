# frozen_string_literal: true

require 'rails_helper'

describe CropFilter do
  subject(:result) { described_class.new(member, params).apply(Crop.all) }

  let(:member) { create(:member) }
  let(:params) { ActionController::Parameters.new(filters) }
  let(:filters) { {} }
  let!(:crop) { create(:crop, name: 'tomato') }
  let!(:other) { create(:crop, name: 'kale') }

  def plant(crop, owner: member, garden: create(:garden, owner:))
    create(:planting, crop:, owner:, garden:)
  end

  context 'without filters' do
    it('leaves every crop') { expect(result).to contain_exactly(crop, other) }
  end

  context 'with a parent' do
    let(:filters) { { parent: crop.id } }
    let!(:variety) { create(:crop, name: 'roma tomato', parent: crop) }

    it('gives its varieties') { expect(result).to eq [variety] }
  end

  context 'with a history of before' do
    let(:filters) { { history: ['before'] } }

    before { plant(crop) }

    it('gives what the member has planted') { expect(result).to eq [crop] }
  end

  context 'with a history of never' do
    let(:filters) { { history: ['never'] } }

    before { plant(crop) }

    it('gives what the member has not planted') { expect(result).to eq [other] }
  end

  context 'with both histories asked for' do
    let(:filters) { { history: %w(before never) } }

    before { plant(crop) }

    it('leaves every crop') { expect(result).to contain_exactly(crop, other) }
  end

  context 'with a variety planted' do
    let(:filters) { { history: ['never'] } }

    before { plant(create(:crop, parent: crop)) }

    it('counts the parent as planted') { expect(result).not_to include crop }
  end

  context 'with friends' do
    let(:filters) { { friends: '1' } }
    let(:friend) { create(:member) }

    before do
      Follow.create!(follower: member, followed: friend)
      plant(crop, owner: friend)
      plant(other)
    end

    it('gives what the people they follow planted') { expect(result).to eq [crop] }
  end

  context 'with seeds' do
    let(:filters) { { seeds: '1' } }

    before do
      create(:seed, owner: member, crop:)
      create(:seed, owner: member, crop: other, finished: true)
    end

    it('gives the crops with seeds that are not used up') { expect(result).to eq [crop] }
  end

  context 'with nearby' do
    let(:filters) { { nearby: '1' } }

    before do
      member.update_columns(latitude: -41.3, longitude: 174.7, location: 'Wellington') # rubocop:disable Rails/SkipsModelValidations
      near = create(:garden).tap { |garden| garden.update_columns(latitude: -41.3, longitude: 174.7) } # rubocop:disable Rails/SkipsModelValidations
      far = create(:garden).tap { |garden| garden.update_columns(latitude: -37.8, longitude: 145.0) } # rubocop:disable Rails/SkipsModelValidations
      plant(crop, owner: near.owner, garden: near)
      plant(other, owner: far.owner, garden: far)
    end

    it('gives what gardeners near them planted') { expect(result).to eq [crop] }
  end

  context 'when suiting the location without weather for it' do
    let(:filters) { { suits: '1' } }

    it('gives none') { expect(result).to be_empty }
  end

  context 'when suiting the location with weather for it' do
    let(:filters) { { season: %w(autumn spring) } }

    before do
      member.update_columns(latitude: -41.3, longitude: 174.7, location: 'Wellington') # rubocop:disable Rails/SkipsModelValidations
      (1..12).each do |month|
        create(:climate_month, year: Time.zone.today.year - 1, month:, temp_mean_c: 10, temp_min_c: 5, temp_max_c: 15)
      end
      crop.update!(ecocrop_record: create(:ecocrop_data, topmn: 12, topmx: 18, gmin: 30, tmin: 0, tmax: 40))
    end

    it('gives the crops that grow there in the season') { expect(result).to eq [crop] }

    context 'with a season the crop does not suit' do
      let(:filters) { { season: ['summer'] } }

      before { (1..12).each { |month| ClimateMonth.where(month:).update_all(temp_max_c: 45, temp_min_c: 22) } } # rubocop:disable Rails/SkipsModelValidations

      it('leaves it out') { expect(result).to be_empty }
    end
  end

  context 'without a member' do
    let(:member) { nil }
    let(:filters) { { history: ['before'], nearby: '1', suits: '1' } }

    it('ignores the filters that need one') { expect(result).to contain_exactly(crop, other) }
  end
end
