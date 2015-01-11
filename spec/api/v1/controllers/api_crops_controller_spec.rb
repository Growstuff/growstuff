require 'spec_helper'

describe Api::V1::CropsController do

  let(:crop) { FactoryGirl.create(:tomato) }

  def check_license(response)
    json = JSON.parse response.body
    json['license'].should_not == nil
    json['license']['name'].should == "Creative Commons Attribution ShareAlike 3.0 Unported"
    json['license']['short_name'].should == "CC-BY-SA"
    json['license']['url'].should == "http://creativecommons.org/licenses/by-sa/3.0/"
    json['license']['credit'].should == "Growstuff"
    json['license']['link'].should == "http://growstuff.org/"
    json['license']['easy_link'].should == '<a href="http://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a> <a href="http://growstuff.org/">Growstuff</a>'
  end

  context "GET crops" do
    it 'has empty list' do
      get '/api/v1/crops'
      expect(response.response_code).to eq(200)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to have_json_size(0).at_path('data')
      check_license response
    end

    it 'has 1 item list' do
      # create a crop instance
      crop
      get '/api/v1/crops'
      expect(response.response_code).to eq(200)
      expect(response.content_type).to eq("application/json")
      expect(response.body).to have_json_size(1).at_path('data')
      check_license response
    end
  end

  context "GET one crop" do
    it 'has crop item' do
      get '/api/v1/crops/' + crop.id.to_s
      expect(response.response_code).to eq(200)
      expect(response.content_type).to eq("application/json")

      json = JSON.parse response.body
      expect(response.body).to have_json_path("data")
      expect(json['data']['name']).to eq("tomato")

      check_license response
    end
  end

end
