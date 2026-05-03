# frozen_string_literal: true

require 'rails_helper'

describe Charts::CropsController do
  describe 'GET charts' do
    let(:crop) { create(:crop) }

    describe 'sunniness' do
      it "returns a successful response" do
        get :sunniness, params: { crop_slug: crop.to_param }
        expect(response).to be_successful
      end

      it "caches the result" do
        cache_key = "#{crop.cache_key_with_version}/sunniness"
        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.day).and_call_original
        get :sunniness, params: { crop_slug: crop.to_param }
      end
    end

    describe 'planted_from' do
      it "returns a successful response" do
        get :planted_from, params: { crop_slug: crop.to_param }
        expect(response).to be_successful
      end

      it "caches the result" do
        cache_key = "#{crop.cache_key_with_version}/planted_from"
        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.day).and_call_original
        get :planted_from, params: { crop_slug: crop.to_param }
      end
    end

    describe 'harvested_for' do
      it "returns a successful response" do
        get :harvested_for, params: { crop_slug: crop.to_param }
        expect(response).to be_successful
      end

      it "caches the result" do
        cache_key = "#{crop.cache_key_with_version}/harvested_for"
        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.day).and_call_original
        get :harvested_for, params: { crop_slug: crop.to_param }
      end
    end
  end
end
