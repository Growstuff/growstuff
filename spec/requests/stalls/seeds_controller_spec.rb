# frozen_string_literal: true

require 'rails_helper'

describe Stalls::SeedsController, flipper: :garden_stall do
  let(:owner) { create(:member) }
  let!(:stall) { create(:stall, :open, member: owner) }
  let(:tomato) { create(:crop, name: 'tomato') }
  let(:kale) { create(:crop, name: 'kale') }
  let!(:shared) { create(:seed, owner:, crop: tomato, variety: 'Black Krim', tradable_to: 'locally') }
  let!(:private_seed) { create(:seed, owner:, crop: kale, tradable_to: 'nowhere') }

  before { sign_in owner }

  describe 'GET /stall/seeds/new' do
    context 'without a search' do
      before { get new_stall_seed_path }

      it 'lists packets marked will trade' do
        expect(Capybara.string(response.body)).to have_css("#stall-seed-#{shared.id}")
      end

      it 'lists the rest too' do
        expect(Capybara.string(response.body)).to have_css("#stall-seed-#{private_seed.id}")
      end
    end

    context 'when searching for a variety' do
      before { get new_stall_seed_path, params: { q: 'krim' } }

      it 'finds the packet' do
        expect(Capybara.string(response.body)).to have_css("#stall-seed-#{shared.id}")
      end

      it 'leaves out the others' do
        expect(Capybara.string(response.body)).to have_no_css("#stall-seed-#{private_seed.id}")
      end
    end

    context 'when the stall is closed' do
      before do
        stall.close!
        get new_stall_seed_path
      end

      it 'goes back to the stall' do
        expect(response).to redirect_to(member_stall_path(owner))
      end
    end
  end

  describe 'POST /stall/seeds' do
    context 'with packets ticked' do
      before { post stall_seeds_path, params: { seed_ids: [shared.id, private_seed.id] } }

      it 'puts them on the stall' do
        expect(stall.seeds).to contain_exactly(shared, private_seed)
      end

      it 'marks the private one as will trade' do
        expect(private_seed.reload.tradable).to be(true)
      end
    end

    context 'with another member\'s packet' do
      before { post stall_seeds_path, params: { seed_ids: [create(:seed).id] } }

      it 'ignores it' do
        expect(stall.seeds).to be_empty
      end
    end

    context 'with nothing ticked' do
      before { post stall_seeds_path }

      it 'asks again' do
        expect(response).to redirect_to(new_stall_seed_path)
      end
    end
  end

  describe 'DELETE /stall/seeds/:id' do
    before do
      stall.put_seeds_on!([shared])
      delete stall_seed_path(shared)
    end

    it 'takes it off the stall' do
      expect(stall.reload.seeds).to be_empty
    end

    it 'keeps it in the seed library' do
      expect(shared.reload).to be_present
    end
  end
end
