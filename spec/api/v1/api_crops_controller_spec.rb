require 'spec_helper'

describe Api::V1::CropsController do

  before(:each) do
    @crop = FactoryGirl.create(:tomato)
    @crop.save
  end

  describe "GET crops index" do
    it 'fetches the crops index' do
      get '/api/v1/crops'
      response.should be_success
      response.content_type.should eq("application/json")
    end
  end

  describe "GET crops index" do
    it 'contains license information' do
      get '/api/v1/crops'

      json = JSON.parse response.body
      json['license'].should_not == nil
      json['license']['name'].should == "Creative Commons Attribution ShareAlike 3.0 Unported"
      json['license']['short_name'].should == "CC-BY-SA"
      json['license']['url'].should == "http://creativecommons.org/licenses/by-sa/3.0/"
      json['license']['credit'].should == "Growstuff"
      json['license']['link'].should == "http://growstuff.org/"
      json['license']['easy_link'].should == '<a href="http://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a> <a href="http://growstuff.org/">Growstuff</a>'
    end
  end

  describe "GET crops single item" do

    it 'fetches one crop' do
      @crop2 = Crop.first
      get '/api/v1/crops/' + @crop2.id.to_s
      response.should be_success
      response.content_type.should eq("application/json")

    end
  end


end
