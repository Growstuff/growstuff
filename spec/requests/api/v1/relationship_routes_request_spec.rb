# frozen_string_literal: true

require 'rails_helper'

# A resource links to what it is related to, and the link is a filtered request for the related resources.
RSpec.describe 'API related resources' do
  include_context 'with an API member'

  let!(:garden) { create(:garden, owner: member) }
  let!(:planting) { create(:planting, owner: member, garden: garden) }
  let!(:harvest) { create(:harvest, owner: member, planting: planting, crop: planting.crop) }
  let!(:other_planting) { create(:planting) }

  # GETs the resource, then what its relationship links to.
  def follow(path, relationship)
    get path, headers: read_headers
    get json['data']['relationships'][relationship]['links']['related'], headers: read_headers
  end

  describe 'related collections' do
    context 'with a member\'s plantings' do
      before { follow "/api/v1/members/#{member.id}", 'plantings' }

      it { expect(ids).to eq([planting.id.to_s]) }
    end

    context 'with a member\'s gardens' do
      before { follow "/api/v1/members/#{member.id}", 'gardens' }

      it { expect(ids).to match_array(member.gardens.map { |g| g.id.to_s }) }
    end

    context 'with a member\'s harvests' do
      before { follow "/api/v1/members/#{member.id}", 'harvests' }

      it { expect(ids).to eq([harvest.id.to_s]) }
    end

    context 'with a garden\'s plantings' do
      before { follow "/api/v1/gardens/#{garden.id}", 'plantings' }

      it { expect(ids).to eq([planting.id.to_s]) }
    end

    context 'with a planting\'s harvests' do
      before { follow "/api/v1/plantings/#{planting.id}", 'harvests' }

      it { expect(ids).to eq([harvest.id.to_s]) }
    end

    context 'with a crop\'s plantings' do
      before { follow "/api/v1/crops/#{planting.crop_id}", 'plantings' }

      it { expect(ids).to eq([planting.id.to_s]) }
    end

    context 'with a relationship that has no records' do
      before { follow "/api/v1/plantings/#{other_planting.id}", 'harvests' }

      it { expect(json['data']).to eq([]) }
    end
  end

  describe 'related single resources' do
    context 'with a planting\'s crop' do
      before { follow "/api/v1/plantings/#{planting.id}", 'crop' }

      it { expect(json['data']['id']).to eq(planting.crop_id.to_s) }
    end

    context 'with a crop that has a parent' do
      let(:parent) { create(:crop) }
      let(:child) { create(:crop, parent: parent) }

      before { follow "/api/v1/crops/#{child.id}", 'parent' }

      it { expect(json['data']['id']).to eq(parent.id.to_s) }
    end

    context 'with a crop that has no parent' do
      before { get "/api/v1/crops/#{planting.crop_id}", headers: read_headers }

      it 'has nothing to link to' do
        expect(json['data']['relationships']['parent']['links']['related']).to be_nil
      end
    end
  end

  describe 'related photos when a record has several' do
    let(:other_photo) { create(:photo, owner: member) }
    let(:photo) { create(:photo, owner: member) }
    let(:second_planting) { create(:planting, owner: member, garden: garden, crop: planting.crop) }

    before do
      [photo, other_photo].each { |p| planting.photos << p }
      second_planting.photos << photo
    end

    # A page of two is two records, however many photos or plantings each matches.
    it 'pages plantings rather than their photos' do
      get "/api/v1/plantings?filter[photo_id]=#{photo.id},#{other_photo.id}&page[size]=2", headers: read_headers
      expect(ids).to contain_exactly(planting.id.to_s, second_planting.id.to_s)
    end

    it 'pages photos rather than their plantings' do
      get "/api/v1/photos?filter[planting_id]=#{planting.id},#{second_planting.id}&page[size]=2", headers: read_headers
      expect(ids).to contain_exactly(photo.id.to_s, other_photo.id.to_s)
    end

    it 'pages photos rather than their crop\'s associations' do
      get "/api/v1/photos?filter[crop_id]=#{planting.crop_id}&page[size]=2", headers: read_headers
      expect(ids).to contain_exactly(photo.id.to_s, other_photo.id.to_s)
    end
  end
end
