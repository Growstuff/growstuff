# frozen_string_literal: true

require 'rails_helper'

describe CropsController do
  shared_context 'login as wrangler' do
    login_member(:crop_wrangling_member)
  end

  subject { response }

  describe "GET crop wrangler homepage" do
    describe 'fetches the crop wrangler homepage' do
      context 'anonymous' do
        before { get :wrangle }

        it { is_expected.not_to be_successful }
      end

      context 'wrangler' do
        include_context 'login as wrangler'
        before { get :wrangle }

        it { is_expected.to be_successful }
        it { is_expected.to render_template("crops/wrangle") }
        it { expect(assigns[:crop_wranglers]).to eq(Role.crop_wranglers) }
      end
    end
  end

  describe "GET crop hierarchy " do
    describe 'fetches the crop hierarchy page' do
      context 'wrangler' do
        include_context 'login as wrangler'
        before { get :hierarchy }

        it { is_expected.to be_successful }
        it { is_expected.to render_template("crops/hierarchy") }
      end
    end
  end

  describe "GET crop search" do
    describe 'fetches the crop search page' do
      let!(:tomato) { FactoryBot.create :tomato }
      let!(:maize)  { FactoryBot.create :maize }
      before { Crop.reindex }
      describe 'search form page' do
        before { get :search }

        it { is_expected.to be_successful }
        it { is_expected.to render_template("crops/search") }
      end

      describe 'perform a search' do
        before { get :search, params: { term: 'tom' } }
        it { expect(assigns(:term)).to eq 'tom' }
        it { expect(assigns(:crops).map(&:name)).to eq ['tomato'] }
      end
    end
  end

  describe "GET RSS feed" do
    describe "returns an RSS feed" do
      before { get :index, format: "rss" }

      it { is_expected.to be_successful }
      it { is_expected.to render_template("crops/index") }
      it { expect(response.content_type).to eq("application/rss+xml") }
    end
  end

  describe 'DELETE destroy' do
    subject { delete :destroy, params: { slug: crop.to_param } }

    let!(:crop) { FactoryBot.create :crop }

    context 'not logged in' do
      it { expect { subject }.not_to change(Crop, :count) }
    end

    context 'logged in as member' do
      it { expect { subject }.not_to change(Crop, :count) }
    end

    context 'wrangler' do
      include_context 'login as wrangler'
      it { expect { subject }.to change(Crop, :count).by -1 }
    end
  end
end
