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
        expect(File).to receive(:read).with(Rails.root.join('config', 'robots.staging.txt'))

        get :robots, format: :text

        expect(response).to be_success
      end 
    end

    context 'subdomain is www' do
      let(:subdomain) { 'www' }

      it 'loads the production robots.txt file' do 
        expect(File).to receive(:read).with(Rails.root.join('config', 'robots.txt'))
        
        get :robots, format: :text

        expect(response).to be_success
      end 
    end

    context 'subdomain is not present' do 
      let(:subdomain) { '' }

      it 'loads the production robots.txt file' do 
        expect(File).to receive(:read).with(Rails.root.join('config', 'robots.txt'))
        
        get :robots, format: :text

        expect(response).to be_success
      end
    end
  end
end
