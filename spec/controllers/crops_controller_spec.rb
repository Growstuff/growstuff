require 'rails_helper'

describe CropsController do
  login_member(:crop_wrangling_member)

  def valid_attributes
    {
      name: "Tomato",
      en_wikipedia_url: 'http://en.wikipedia.org/wiki/Tomato',
      approval_status: 'approved'
    }
  end

  subject { response }

  describe "GET crop wrangler homepage" do
    describe 'fetches the crop wrangler homepage' do
      before { get :wrangle }
      it { is_expected.to be_success }
      it { is_expected.to render_template("crops/wrangle") }
      it { expect(assigns[:crop_wranglers]).to eq(Role.crop_wranglers) }
    end
  end

  describe "GET crop hierarchy " do
    describe 'fetches the crop hierarchy page' do
      before { get :hierarchy }
      it { is_expected.to be_success }
      it { is_expected.to render_template("crops/hierarchy") }
    end
  end

  describe "GET crop search" do
    describe 'fetches the crop search page' do
      before { get :search }
      it { is_expected.to be_success }
      it { is_expected.to render_template("crops/search") }
    end
  end

  describe "GET RSS feed" do
    describe "returns an RSS feed" do
      before { get :index, format: "rss" }
      it { is_expected.to be_success }
      it { is_expected.to render_template("crops/index") }
      it { expect(response.content_type).to eq("application/rss+xml") }
    end
  end
end
