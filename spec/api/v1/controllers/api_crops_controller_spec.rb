require 'spec_helper'

describe Api::V1::CropsController do

  let(:crop) { FactoryGirl.create(:tomato) }

  def check_license(response)
    json = JSON.parse response.body
    expect(json['license']).to_not eq(nil)
    expect(json['license']['name']).to eq("Creative Commons Attribution ShareAlike 3.0 Unported")
    expect(json['license']['short_name']).to eq("CC-BY-SA")
    expect(json['license']['url']).to eq("http://creativecommons.org/licenses/by-sa/3.0/")
    expect(json['license']['credit']).to eq("Growstuff")
    expect(json['license']['link']).to eq("http://growstuff.org/")
    expect(json['license']['easy_link']).to eq('<a href="http://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a> <a href="http://growstuff.org/">Growstuff</a>')
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
