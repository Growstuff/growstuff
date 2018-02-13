require 'rails_helper'

feature "home page" do
  let(:seed) { create :seed }
  let(:planting) { create :planting }
  let(:member) { create :member }
  let(:photo) { create :photo }

  before { visit root_path }
  subject { page }

  describe 'shows home page' do
    it { is_expected.to have_text 'View all crops' }
  end

  describe 'shows seeds' do
    let!(:tradable_seed) { FactoryBot.create :tradable_seed }
    let!(:finished_seed) { FactoryBot.create :tradable_seed, finished: true }
    let!(:untradable_seed) { FactoryBot.create :untradable_seed }
    describe 'shows tradeable seeds' do
      it { is_expected.to have_text tradable_seed }
      it { is_expected.not_to have_text finished_seed }
      it { is_expected.not_to have_text untradable_seed }
    end
    it { is_expected.to have_text 'View all seeds' }
  end

  context 'when anonymous' do
  end

  context "when signed in" do
    background { login_as member }
    it { is_expected.to have_text 'Welcome' }
  end
end
