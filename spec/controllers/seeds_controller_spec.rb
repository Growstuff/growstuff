# frozen_string_literal: true

require 'rails_helper'

describe SeedsController do
  let(:owner) { create(:member) }

  describe "GET index" do
    describe "picks up owner from params" do
      before do
        get :index, params: { member_slug: owner.slug }
      end

      it { expect(assigns(:owner)).to eq(owner) }
    end

    describe "sorting by nearness on a crop" do
      let(:crop) { create(:crop) }
      let(:viewer) { create(:london_member) }
      let!(:far_seed) { create(:seed, crop:, owner: create(:south_pole_member), tradable_to: 'locally') }
      let!(:unlocated_seed) { create(:seed, crop:, owner: create(:member), tradable_to: 'locally') }
      let!(:near_seed) { create(:seed, crop:, owner: create(:london_member), tradable_to: 'locally') }

      it 'lists nearest first when signed in with a location' do
        sign_in viewer
        get :index, params: { crop_slug: crop.slug }
        expect(assigns(:seeds).to_a).to eq([near_seed, far_seed, unlocated_seed])
      end

      it 'does not sort by distance when signed out' do
        get :index, params: { crop_slug: crop.slug }
        expect(assigns(:sort_by_distance)).to be false
      end
    end
  end

  describe 'GET index filters' do
    let(:crop) { create(:crop) }
    let!(:own_seed) { create(:seed, crop:, source: 'my own seed saving', tradable_to: 'locally') }
    let!(:bought_seed) { create(:seed, crop:, source: 'retail outlet', tradable_to: 'locally') }
    let!(:traded_seed) { create(:seed, crop:, source: 'traded from another person', tradable_to: 'locally') }

    context 'when choosing my own saving' do
      before { get :index, params: { from: 'own' } }

      it { expect(assigns(:seeds)).to contain_exactly(own_seed) }
    end

    context 'when choosing bought' do
      before { get :index, params: { from: 'bought' } }

      it { expect(assigns(:seeds)).to contain_exactly(bought_seed) }
    end

    context 'when choosing traded' do
      before { get :index, params: { from: 'traded' } }

      it { expect(assigns(:seeds)).to contain_exactly(traded_seed) }
    end

    context 'when choosing heirloom only' do
      let!(:heirloom_seed) { create(:seed, crop:, heirloom: 'heirloom', tradable_to: 'locally') }

      before { get :index, params: { from: 'heirloom' } }

      it { expect(assigns(:seeds)).to contain_exactly(heirloom_seed) }
    end

    context 'when choosing past sow-by' do
      let!(:expired_seed) { create(:seed, crop:, plant_before: Date.new(2020, 12, 31), tradable_to: 'locally') }

      before { get :index, params: { past: '1' } }

      it { expect(assigns(:seeds)).to include(expired_seed) }
    end

    context 'when a filter is chosen' do
      before { get :index, params: { from: 'own' } }

      it { expect(assigns(:filtered)).to be true }
    end

    context 'without a filter' do
      before { get :index }

      it { expect(assigns(:filtered)).to be false }
    end
  end

  describe 'GET index of one crop' do
    let(:tomato) { create(:crop, name: 'tomato') }
    let(:brandywine) { create(:crop, name: 'Brandywine tomato', parent: tomato) }
    let!(:variety_seed) { create(:seed, crop: brandywine, tradable_to: 'locally') }
    let!(:parent_seed) { create(:seed, crop: tomato, tradable_to: 'locally') }
    let!(:other_seed) { create(:seed, tradable_to: 'locally') }

    context 'when choosing a crop' do
      before { get :index, params: { crop: tomato.slug } }

      it { expect(assigns(:seeds)).to contain_exactly(variety_seed, parent_seed) }
      it { expect(assigns(:search_crop)).to eq tomato }
      it { expect(assigns(:seed_total)).to eq 2 }
    end

    context 'when the crop does not exist' do
      before { get :index, params: { crop: 'not-a-crop' } }

      it { expect(assigns(:seeds)).to include(variety_seed, parent_seed, other_seed) }
      it { expect(assigns(:search_crop)).to be_nil }
    end

    context 'on a crop\'s own page' do
      before { get :index, params: { crop_slug: tomato.slug, crop: brandywine.slug } }

      it { expect(assigns(:search_crop)).to be_nil }
    end
  end

  describe 'GET index as the results alone' do
    let(:owner) { create(:member) }
    let(:tomato) { create(:crop, name: 'tomato') }
    let(:json) { response.parsed_body }

    before do
      create(:seed, owner:, crop: tomato)
      request.headers['X-Seed-Library'] = 'results'
      get :index, params: { member_slug: owner.slug, crop: tomato.slug }, format: :json
    end

    it { expect(response.media_type).to eq 'application/json' }
    it { expect(json['tabs']).to include('In stock') }
    it { expect(json['results']).to include('seed-shelf') }
    it { expect(json['results']).not_to include('<html') }
    it { expect(json['crop']).to eq('name' => 'tomato', 'slug' => tomato.slug) }
    it { expect(response.headers['Vary']).to include('X-Seed-Library') }
  end

  describe 'GET index pages of whole piles' do
    let(:owner) { create(:member) }
    let(:crops) { %w(apple beet carrot).map { |name| create(:crop, name:) } }

    before do
      stub_const('SeedsController::PER_PAGE', 2)
      create_list(:seed, 5, owner:, crop: crops.first)
      create_list(:seed, 4, owner:, crop: crops.second)
      create_list(:seed, 3, owner:, crop: crops.third)
    end

    context 'on the first page' do
      before { get :index, params: { member_slug: owner.slug } }

      it { expect(assigns(:seeds).size).to eq 9 }
      it { expect(assigns(:seeds).map(&:crop).uniq).to eq crops.first(2) }
      it { expect(assigns(:piles).total_entries).to eq 3 }
    end

    context 'on the second page' do
      before { get :index, params: { member_slug: owner.slug, page: 2 } }

      it { expect(assigns(:seeds).map(&:crop).uniq).to eq [crops.third] }
      it { expect(assigns(:seeds).size).to eq 3 }
    end

    context 'when asking for csv' do
      before { get :index, params: { member_slug: owner.slug }, format: :csv }

      it { expect(assigns(:piles)).to be_nil }
      it { expect(assigns(:seeds).size).to eq 12 }
    end
  end

  describe 'GET index grouped by year' do
    let(:owner) { create(:member) }

    before do
      create(:seed, owner:, saved_at: Date.new(2021, 5, 6))
      create(:seed, owner:, saved_at: nil)
      get :index, params: { member_slug: owner.slug, group: 'year' }
    end

    it { expect(assigns(:shelves).keys).to eq [Time.zone.today.year.to_s, '2021'] }
  end

  describe 'GET index of everyone\'s seeds' do
    let!(:shared_seed) { create(:seed, tradable_to: 'locally') }
    let!(:private_seed) { create(:seed, tradable_to: 'nowhere') }

    context 'with no owner' do
      before { get :index }

      it { expect(assigns(:seeds)).to contain_exactly(shared_seed) }
      it { expect(assigns(:shared_totals)).to eq(packets: 1, gardeners: 1) }
    end

    context 'with an owner' do
      let(:owner) { private_seed.owner }

      before { get :index, params: { member_slug: owner.slug } }

      it { expect(assigns(:seeds)).to contain_exactly(private_seed) }
      it { expect(assigns(:shared_totals)).to be_nil }
    end

    context 'when asking for csv' do
      before { get :index, format: :csv }

      it { expect(assigns(:seeds)).to include(private_seed) }
    end
  end

  describe 'GET index scoped to people near or followed' do
    let(:viewer) { create(:london_member) }
    let!(:followed_seed) { create(:seed, owner: followed, tradable_to: 'locally') }
    let!(:near_seed) { create(:seed, owner: create(:london_member), tradable_to: 'locally') }
    let!(:far_seed) { create(:seed, owner: create(:south_pole_member), tradable_to: 'locally') }
    let(:followed) { create(:south_pole_member) }

    before do
      create(:follow, follower: viewer, followed:)
      sign_in viewer
    end

    context 'when following' do
      before { get :index, params: { scope: 'following' } }

      it { expect(assigns(:seeds)).to contain_exactly(followed_seed) }
    end

    context 'when near me' do
      before { get :index, params: { scope: 'near' } }

      it { expect(assigns(:seeds)).to contain_exactly(near_seed) }
    end

    context 'when within a distance' do
      before { get :index, params: { within: '50' } }

      it { expect(assigns(:seeds)).to contain_exactly(near_seed) }
    end
  end

  describe 'GET index counts' do
    let(:owner) { create(:member) }

    before do
      create(:seed, owner:)
      create(:seed, owner:, finished: true)
      create(:seed, owner:, plant_before: Date.new(2020, 12, 31))
      get :index, params: { member_slug: owner.slug }
    end

    it { expect(assigns(:in_stock_count)).to eq 2 }
    it { expect(assigns(:finished_count)).to eq 1 }
    it { expect(assigns(:past_count)).to eq 2 }
    it { expect(assigns(:stats)).to include(packets: 2) }
  end

  describe 'GET new' do
    before { sign_in owner }

    it { expect(response).to be_successful }

    context 'with parent planting' do
      let!(:planting) { create(:planting, owner:) }

      before do
        get :new, params: { planting_slug: planting.to_param }
      end

      it { expect(assigns(:planting)).to eq(planting) }
    end
  end
end
