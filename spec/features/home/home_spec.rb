require 'rails_helper'

feature "home page" do
  let(:seed) { create :seed }
  let(:planting) { create :planting }
  let(:member) { create :member }
  let(:photo) { create :photo }

  before { visit root_path }
  subject { page }

  shared_examples 'shows home page' do
    it { is_expected.to have_text 'View all crops' }
  end

  shared_examples 'shows seeds' do
    let!(:tradable_seed) { FactoryBot.create :tradable_seed }
    let!(:finished_seed) { FactoryBot.create :tradable_seed, finished: true }
    let!(:untradable_seed) { FactoryBot.create :untradable_seed }
    describe 'shows tradeable seeds' do
      it { is_expected.to have_link seed_path(tradable_seed) }
    end
    describe "doesn't show untradeable seed" do
      it { is_expected.not_to have_link seed_path(finished_seed) }
      it { is_expected.not_to have_link seed_path(untradable_seed) }
    end
    it { is_expected.to have_text 'View all seeds' }
  end

  context 'when anonymous' do
    include_examples 'shows home page'
    include_examples 'shows seeds'
    it { is_expected.to have_text 'community of food gardeners' }
  end

  context "when signed in" do
    background { login_as member }
    include_examples 'shows home page'
    include_examples 'shows seeds'
  end
end
