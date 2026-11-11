# frozen_string_literal: true

require 'rails_helper'

describe Admin::FeaturesController do
  let(:admin) { create(:admin_member) }
  let(:page) { Capybara.string(response.body) }

  describe 'member grants' do
    let(:member) { create(:member) }

    before { sign_in admin }

    it 'enables a feature for the selected member' do
      post add_member_admin_feature_path('job_ideas'), params: { login_name: member.login_name }
      expect(Feature.enabled?(:job_ideas, member)).to be true
    end

    it 'lists granted members' do
      Feature.find(:job_ideas).enable_member(member)
      get admin_features_path
      expect(page).to have_css('#feature-job_ideas a', text: member.login_name)
    end

    it 'allows a granted member to access the feature' do
      post add_member_admin_feature_path('job_ideas'), params: { login_name: member.login_name }
      sign_in member
      get job_ideas_path
      expect(response).to have_http_status(:ok)
    end

    it 'keeps the feature unavailable to other members' do
      post add_member_admin_feature_path('job_ideas'), params: { login_name: member.login_name }
      get job_ideas_path
      expect(response).to have_http_status(:not_found)
    end

    it 'removes a member grant' do
      Feature.find(:job_ideas).enable_member(member)
      delete remove_member_admin_feature_path('job_ideas'), params: { member_id: member.id }
      expect(Feature.enabled?(:job_ideas, member)).to be false
    end

    it 'reports an unknown username' do
      post add_member_admin_feature_path('job_ideas'), params: { login_name: 'unknown member' }
      expect(flash[:alert]).to be_present
    end

    context 'with a non-admin' do
      before { sign_in member }

      it 'rejects adding a grant' do
        post add_member_admin_feature_path('job_ideas'), params: { login_name: member.login_name }
        expect(Feature.enabled?(:job_ideas, member)).to be false
      end

      it 'rejects removing a grant' do
        Feature.find(:job_ideas).enable_member(member)
        delete remove_member_admin_feature_path('job_ideas'), params: { member_id: member.id }
        expect(Feature.enabled?(:job_ideas, member)).to be true
      end
    end
  end

  describe '#index' do
    context 'with an admin' do
      before do
        sign_in admin
        get admin_features_path
      end

      it 'lists job ideas' do
        expect(page).to have_css('#feature-job_ideas', text: 'Job ideas')
      end

      it 'shows it is off' do
        expect(page).to have_css('#feature-job_ideas .badge', text: 'Off')
      end

      it 'offers to switch it on' do
        expect(page).to have_button('Switch on')
      end
    end

    context 'with job ideas switched on', flipper: :job_ideas do
      before do
        sign_in admin
        get admin_features_path
      end

      it 'offers to switch it off' do
        expect(page).to have_button('Switch off')
      end
    end

    context 'with a member who is not an admin' do
      before do
        sign_in create(:member)
        get admin_features_path
      end

      it 'turns them away' do
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when signed out' do
      before { get admin_features_path }

      it 'sends them to sign in' do
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end

  describe '#update' do
    before { sign_in admin }

    context 'when switching on' do
      before { patch admin_feature_path('job_ideas'), params: { enabled: true } }

      it 'switches it on' do
        expect(Flipper).to be_enabled(:job_ideas)
      end

      it 'goes back to the features' do
        expect(response).to redirect_to(admin_features_path)
      end

      it 'says so' do
        expect(flash[:notice]).to eq 'Job ideas is now on.'
      end
    end

    context 'when switching off', flipper: :job_ideas do
      before { patch admin_feature_path('job_ideas'), params: { enabled: false } }

      it 'switches it off' do
        expect(Flipper).not_to be_enabled(:job_ideas)
      end
    end

    context 'with a feature that is not on the list' do
      before { patch admin_feature_path('anything_else'), params: { enabled: true } }

      it 'is not found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with a member who is not an admin' do
      before do
        sign_in create(:member)
        patch admin_feature_path('job_ideas'), params: { enabled: true }
      end

      it 'leaves it off' do
        expect(Flipper).not_to be_enabled(:job_ideas)
      end
    end
  end
end
