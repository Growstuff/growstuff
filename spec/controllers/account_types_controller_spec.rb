require 'rails_helper'

describe AccountTypesController do
  subject { response }

  context 'anon' do
    describe '#index' do
      before { get :index }
      it { is_expected.not_to be_success }
    end
  end
  context 'member' do
    login_member(:member)
    describe '#index' do
      before { get :index }
      it { is_expected.not_to be_success }
    end
  end
  context 'admin' do
    login_member(:admin_member)
    describe '#index' do
      let!(:aaa) { FactoryBot.create :account_type, name: 'aaa' }
      let!(:zzz) { FactoryBot.create :account_type, name: 'zzz' }
      before { get :index }
      it { is_expected.to be_success }
      it { expect(assigns[:account_types].first).to eql(aaa) }
      it { expect(assigns[:account_types].last).to eql(zzz) }
    end
  end
end
