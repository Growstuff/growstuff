# frozen_string_literal: true

require 'rails_helper'

describe RobotsController do
  describe '#robots' do
    let(:production_filename) { 'config/robots.txt'         }
    let(:staging_filename)    { 'config/robots.staging.txt' }

    before do
      @request.host = "#{subdomain}.localhost.com"
    end

    context 'subdomain is staging' do
      let(:subdomain) { 'staging' }

      it 'loads the staging robots.txt file' do
        get :robots

        expect(response).to be_successful
        expect(response.body).to eq(File.read(staging_filename))
      end
    end

    context 'subdomain is www' do
      let(:subdomain) { 'www' }

      it 'loads the production robots.txt file' do
        get :robots

        expect(response).to be_successful
        expect(response.body).to eq(File.read(production_filename))
      end
    end

    context 'subdomain is not present' do
      let(:subdomain) { '' }

      it 'loads the production robots.txt file' do
        get :robots

        expect(response).to be_successful
        expect(response.body).to eq(File.read(production_filename))
      end
    end

    context 'subdomain is nonsense' do
      let(:subdomain) { '1874ajnfien' }

      it 'loads the production robots.txt file' do
        get :robots

        expect(response).to be_successful
        expect(response.body).to eq(File.read(production_filename))
      end
    end
  end
end
