# frozen_string_literal: true

require 'rails_helper'

describe Admin::CropsController do
  let(:wrangler) { create(:crop_wrangling_member) }
  let(:page) { Capybara.string(response.body) }
  let!(:crop) { create(:crop, name: 'initial') }

  before { sign_in wrangler }

  describe 'GET /admin/crops' do
    before { get admin_crops_path }

    it 'redirects to the wrangle page' do
      expect(response).to redirect_to(wrangle_crops_path)
    end
  end

  describe 'GET /admin/crops/recently_edited' do
    subject(:request) { get recently_edited_admin_crops_path }

    context 'with a regular member' do
      before { sign_in create(:member) }

      it 'is refused' do
        request
        expect(response).not_to be_successful
      end
    end

    context 'when an edit has an editor' do
      let(:editor) { create(:member, login_name: 'carol') }

      before do
        crop.versions.last.update!(whodunnit: editor.id.to_s)
        request
      end

      it 'links to the editor' do
        expect(page).to have_link('carol', href: member_path(editor))
      end
    end

    context 'when an edit has no recorded editor' do
      before { request }

      it 'says the editor is unknown' do
        expect(page).to have_text('by unknown')
      end
    end

    context 'when an edit changed the creator' do
      let(:previous_creator) { create(:member, login_name: 'dave') }

      before do
        crop.update!(creator: previous_creator)
        request
      end

      it 'links to the creator by name' do
        expect(page).to have_link('dave', href: member_path(previous_creator))
      end
    end

    context 'when an edit changed the parent' do
      let(:parent) { create(:crop, name: 'brassica') }

      before do
        crop.update!(parent:)
        request
      end

      it 'links to the parent by name' do
        expect(page).to have_link('brassica', href: crop_path(parent))
      end
    end

    context 'with more edits than fit on one page' do
      before { create_list(:crop, 50) }

      it 'shows page links' do
        request
        expect(page).to have_css('.pagination')
      end

      it 'shows the oldest edit on the next page' do
        get recently_edited_admin_crops_path(page: 2)
        expect(page).to have_link('initial', href: crop_path(crop))
      end

      it 'leaves the oldest edit off the first page' do
        request
        expect(page).not_to have_link('initial')
      end
    end
  end

  describe 'recording who made an edit' do
    subject(:whodunnit) { crop.versions.last.whodunnit }

    before { patch crop_path(crop), params: { crop: { name: 'renamed' } } }

    it { is_expected.to eq wrangler.id.to_s }
  end
end
