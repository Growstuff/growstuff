# frozen_string_literal: true

require 'rails_helper'

describe RobotsController do
  describe '#robots' do
    let(:production_filename) { 'config/robots.txt'         }
    let(:staging_filename)    { 'config/robots.staging.txt' }

    before do
      @request.host = "#{subdomain}.localhost.com"
    end

    context 'when the subdomain is staging' do
      let(:subdomain) { 'staging' }

      describe 'loads the staging robots.txt file' do
        before { get :robots }

        it { expect(response).to be_successful }
        it { expect(response.body).to eq(File.read(staging_filename)) }
      end
    end

    context 'when the subdomain is www' do
      let(:subdomain) { 'www' }

      describe 'loads the production robots.txt file' do
        before { get :robots }

        it { expect(response).to be_successful }
        it { expect(response.body).to eq(File.read(production_filename)) }
      end
    end

    context 'without a subdomain' do
      let(:subdomain) { '' }

      describe 'loads the production robots.txt file' do
        before { get :robots }

        it { expect(response).to be_successful }
        it { expect(response.body).to eq(File.read(production_filename)) }
      end
    end

    context 'when the subdomain is nonsense' do
      let(:subdomain) { '1874ajnfien' }

      describe 'loads the production robots.txt file' do
        before { get :robots }

        it { expect(response).to be_successful }
        it { expect(response.body).to eq(File.read(production_filename)) }
      end
    end
  end
end
