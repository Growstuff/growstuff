# frozen_string_literal: true

require 'rails_helper'

describe 'Admin crops' do
  let(:wrangler) { create(:crop_wrangling_member) }
  let(:editor) { create(:crop_wrangling_member, login_name: 'carol') }
  let!(:crop) { create(:crop, name: 'initial') }

  before { sign_in wrangler }

  describe 'GET /admin/crops' do
    before { get admin_crops_path }

    it { expect(response).to redirect_to(wrangle_crops_path) }
  end

  describe 'GET /admin/crops/recently_edited' do
    context 'when an edit has an editor' do
      before do
        crop.versions.last.update!(whodunnit: editor.id.to_s)
        get recently_edited_admin_crops_path
      end

      it { expect(response.body).to include('carol') }
    end

    context 'when an edit has no recorded editor' do
      before { get recently_edited_admin_crops_path }

      it { expect(Capybara.string(response.body)).to have_text('by unknown') }
    end

    context 'when an edit changed the creator' do
      let(:previous_creator) { create(:member, login_name: 'dave') }

      before do
        crop.update!(creator: previous_creator)
        get recently_edited_admin_crops_path
      end

      it { expect(Capybara.string(response.body)).to have_link('dave', href: member_path(previous_creator)) }
    end

    context 'when an edit changed the parent' do
      let(:parent) { create(:crop, name: 'brassica') }

      before do
        crop.update!(parent:)
        get recently_edited_admin_crops_path
      end

      it { expect(Capybara.string(response.body)).to have_link('brassica', href: crop_path(parent)) }
    end

    context 'with more edits than fit on a page' do
      before do
        create_list(:crop, 51)
        get recently_edited_admin_crops_path
      end

      it { expect(Capybara.string(response.body)).to have_css('.pagination') }
    end
  end

  describe 'PATCH /crops/:slug' do
    subject(:editor_id) { crop.versions.last.whodunnit }

    before do
      patch crop_path(crop), params: { crop: { name: 'renamed' } }
    end

    it { is_expected.to eq wrangler.id.to_s }
  end
end
