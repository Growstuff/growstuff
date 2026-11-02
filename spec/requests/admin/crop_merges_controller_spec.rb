# frozen_string_literal: true

require 'rails_helper'

describe Admin::CropMergesController do
  let(:wrangler) { create(:crop_wrangling_member) }
  let(:page) { Capybara.string(response.body) }
  let!(:duplicate) { create(:crop, name: 'habanero') }
  let!(:target) { create(:crop, name: 'habanero pepper') }

  describe 'GET /admin/crops/merge' do
    context 'when signed out' do
      before { get admin_crop_merge_path }

      it 'asks for a sign in' do
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context 'with a regular member' do
      before do
        sign_in create(:member)
        get admin_crop_merge_path
      end

      it 'is refused' do
        expect(response).not_to be_successful
      end
    end

    context 'with a wrangler' do
      before { sign_in wrangler }

      context 'without choosing a crop' do
        before { get admin_crop_merge_path }

        it 'offers a search for the duplicate' do
          expect(page).to have_field('Search for the duplicate crop')
        end

        it 'does not offer a search for the crop to keep yet' do
          expect(page).to have_no_field('Search for the crop to keep')
        end
      end

      context 'when searching for the duplicate' do
        before { get admin_crop_merge_path(q: 'habanero') }

        it 'lists the crop to choose as the duplicate' do
          expect(page).to have_link('Choose', href: admin_crop_merge_path(duplicate_id: duplicate.id))
        end
      end

      context 'when the search finds nothing' do
        before { get admin_crop_merge_path(q: 'zzzzzz') }

        it 'says so' do
          expect(page).to have_text('No crops match "zzzzzz".')
        end
      end

      context 'with the duplicate chosen' do
        before { get admin_crop_merge_path(duplicate_id: duplicate.id) }

        it 'names the duplicate' do
          expect(page).to have_css('#duplicate-step', text: 'habanero')
        end

        it 'offers a search for the crop to keep' do
          expect(page).to have_field('Search for the crop to keep')
        end
      end

      context 'when searching for the crop to keep' do
        before { get admin_crop_merge_path(duplicate_id: duplicate.id, q: 'habanero') }

        it 'lists the other match to choose' do
          expect(page).to have_link('Choose', href: admin_crop_merge_path(target_id: target.id, duplicate_id: duplicate.id))
        end

        it 'leaves the duplicate out of the matches' do
          expect(page).to have_css('#target-step li', count: 1)
        end
      end

      context 'with both crops chosen' do
        before do
          create(:planting, crop: duplicate)
          get admin_crop_merge_path(duplicate_id: duplicate.id, target_id: target.id)
        end

        it 'offers to merge' do
          expect(page).to have_button('Merge habanero into habanero pepper')
        end

        it 'counts the plantings that move' do
          expect(page).to have_css('#confirm-step tr', text: /Plantings\s+1/)
        end
      end

      context 'with the same crop chosen twice' do
        before { get admin_crop_merge_path(duplicate_id: duplicate.id, target_id: duplicate.id) }

        it 'asks for the crop to keep again' do
          expect(page).to have_field('Search for the crop to keep')
        end
      end
    end
  end

  describe 'POST /admin/crops/merge' do
    subject(:merge) { post admin_crop_merge_path, params: { duplicate_id: duplicate.id, target_id: target.id } }

    context 'with a regular member' do
      before { sign_in create(:member) }

      it 'does not delete the duplicate' do
        expect { merge }.not_to change(Crop, :count)
      end
    end

    context 'with a wrangler' do
      before { sign_in wrangler }

      it 'deletes the duplicate' do
        expect { merge }.to change(Crop, :count).by(-1)
      end

      it 'moves the duplicate plantings to the crop kept' do
        planting = create(:planting, crop: duplicate)
        merge
        expect(planting.reload.crop).to eq target
      end

      it 'goes to the crop kept' do
        merge
        expect(response).to redirect_to(crop_path(target))
      end

      it 'says what was merged' do
        merge
        expect(flash[:notice]).to eq 'Merged habanero into habanero pepper.'
      end
    end

    context 'when both crops are the same' do
      subject(:merge) { post admin_crop_merge_path, params: { duplicate_id: duplicate.id, target_id: duplicate.id } }

      before { sign_in wrangler }

      it 'does not delete the crop' do
        expect { merge }.not_to change(Crop, :count)
      end

      it 'explains' do
        merge
        expect(flash[:alert]).to eq 'Choose two different crops to merge.'
      end
    end
  end
end
