# frozen_string_literal: true

require 'rails_helper'

describe Charts::GardensController do
  include Devise::Test::ControllerHelpers

  let(:garden) { FactoryBot.create :garden }

  context "when not signed in" do
    describe 'GET timeline' do
      before { get :timeline, params: { garden_slug: garden.to_param } }

      it { expect(response).to be_successful }
    end
  end

  context "when signed in" do
    before { sign_in member }

    let!(:member) { FactoryBot.create(:member) }

    describe 'GET timeline' do
      before { get :timeline, params: { garden_slug: garden.to_param } }

      it { expect(response).to be_successful }
    end
  end
end
