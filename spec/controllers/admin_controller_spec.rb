# frozen_string_literal: true

require 'rails_helper'

describe AdminController do
  login_member(:admin_member)

  describe "GET admin/newsletter" do
    before { get :newsletter }

    describe 'fetches the admin newsletter page' do
      it { expect(response).to be_successful }
      it { expect(response).to render_template("admin/newsletter") }
    end

    describe 'assigns @members' do
      let!(:m) { FactoryBot.create(:newsletter_recipient_member) }

      it { expect(assigns(:members)).to eq [m] }
    end
  end
end
