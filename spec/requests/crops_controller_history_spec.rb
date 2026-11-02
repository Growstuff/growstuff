# frozen_string_literal: true

require 'rails_helper'

describe CropsController do
  let(:page) { Capybara.string(response.body) }
  let(:editor) { create(:member, login_name: 'carol') }
  let(:crop) { create(:crop, name: 'lettuce') }

  def edit_as(member, **attributes)
    PaperTrail.request(whodunnit: member.id.to_s) { crop.update!(**attributes) }
  end

  describe 'GET /crops/:slug/history' do
    context 'when signed out' do
      before do
        edit_as(editor, description: 'A leafy salad crop.')
        get history_crop_path(crop)
      end

      it 'is shown' do
        expect(response).to be_successful
      end

      it 'names the crop' do
        expect(page).to have_css('h1', text: 'Edit history of lettuce')
      end

      it 'links to who made the edit' do
        expect(page).to have_link('carol', href: member_path(editor))
      end

      it 'shows what changed' do
        expect(page).to have_css('.changes', text: 'A leafy salad crop.')
      end

      it 'links back to the crop' do
        expect(page).to have_link('Back to lettuce', href: crop_path(crop))
      end
    end

    context 'with an edit that changed the parent' do
      let(:parent) { create(:crop, name: 'salad greens') }

      before do
        crop.update!(parent:)
        get history_crop_path(crop)
      end

      it 'shows the parent by name' do
        expect(page).to have_link('salad greens', href: crop_path(parent))
      end
    end

    context 'with more edits than fit on one page' do
      before do
        51.times { |count| crop.update!(description: "Edit number #{count}") }
        get history_crop_path(crop)
      end

      it 'shows page links' do
        expect(page).to have_css('.pagination')
      end

      it 'leaves the oldest edit for the next page' do
        expect(page).to have_no_css('.edit-event', text: 'Create')
      end
    end

    context 'with the second page of edits' do
      before do
        51.times { |count| crop.update!(description: "Edit number #{count}") }
        get history_crop_path(crop, page: 2)
      end

      it 'shows the oldest edit' do
        expect(page).to have_css('.edit-event', text: 'Create')
      end
    end
  end

  describe 'GET /crops/:slug' do
    context 'when the last edit has an editor' do
      before do
        edit_as(editor, description: 'A leafy salad crop.')
        get crop_path(crop)
      end

      it 'says who last edited it' do
        expect(page).to have_css('.crop-last-edit', text: /Last edited by carol on/)
      end

      it 'links to the editor' do
        expect(page).to have_css(%(.crop-last-edit a[href="#{member_path(editor)}"]), text: 'carol')
      end

      it 'links to the history' do
        expect(page).to have_css(%(.crop-last-edit a[href="#{history_crop_path(crop)}"]), text: 'View history')
      end

      it 'does not list the changes on the page' do
        expect(page).to have_no_css('.changes')
      end

      it 'does not have an edit history section' do
        expect(page).to have_no_css('h2', text: 'Edit history')
      end
    end

    context 'when the last edit has no recorded editor' do
      before { get crop_path(crop) }

      it 'gives the date without a name' do
        expect(page).to have_css('.crop-last-edit', text: /\ALast edited on/)
      end
    end
  end
end
