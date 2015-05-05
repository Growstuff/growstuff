require 'rails_helper'
require 'pry'

describe RobotsController do
  describe '#robots' do

    before do
      @request.host = "#{ subdomain }.localhost.com"
    end

    context 'subdomain is staging' do
      let(:subdomain) { 'staging' }

      it 'loads the staging robots.txt file' do
        get :robots

        expect(response).to be_success
        expect(response.body).to eq(File.read('config/robots.staging.txt'))
      end
    end

    context 'subdomain is www' do
      let(:subdomain) { 'www' }

      it 'loads the production robots.txt file' do
        get :robots

        expect(response).to be_success
        expect(response.body).to eq(File.read('config/robots.txt'))
      end
    end

    context 'subdomain is not present' do
      let(:subdomain) { '' }

      it 'loads the production robots.txt file' do
        get :robots

        expect(response).to be_success
        expect(response.body).to eq(File.read('config/robots.txt'))
      end
    end
  end
end
