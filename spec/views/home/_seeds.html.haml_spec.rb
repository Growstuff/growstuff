require 'rails_helper'

describe 'home/_seeds.html.haml', type: 'view' do
  let!(:seed) { FactoryBot.create(:tradable_seed, owner: owner) }
  let(:owner) { FactoryBot.create(:london_member) }
  before { render }

  it 'has a heading' do
    assert_select 'h2', 'Seeds available to trade'
  end

  it { expect(rendered).to have_content seed.tradable_to }
  it { expect(rendered).to have_content seed.owner.location }
  it { expect(rendered).to have_link(href: seed_path(seed)) }
end
