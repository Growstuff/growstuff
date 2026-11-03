# frozen_string_literal: true

require 'rails_helper'

describe 'crops/_approval_status_message' do
  subject { rendered }

  context 'when crop is pending without request notes' do
    let(:crop) { build_stubbed(:crop_request, request_notes: nil) }

    before do
      render partial: 'crops/approval_status_message', locals: { crop: }
    end

    it 'renders the localized pending title' do
      expect(rendered).to have_content(I18n.t('crops.approval_status_message.pending_title'))
    end

    it 'renders the localized requester message' do
      expected_text = I18n.t(
        'crops.approval_status_message.requested_by',
        requester: crop.requester,
        time_ago: time_ago_in_words(crop.created_at)
      )
      expect(rendered).to have_content(expected_text)
    end
  end

  context 'when crop is pending with request notes' do
    let(:crop) { build_stubbed(:crop_request, request_notes: 'Need this for my garden.') }

    before do
      render partial: 'crops/approval_status_message', locals: { crop: }
    end

    it 'renders the localized pending title' do
      expect(rendered).to have_content(I18n.t('crops.approval_status_message.pending_title'))
    end

    it 'renders the localized request notes' do
      expected_text = I18n.t(
        'crops.approval_status_message.request_notes',
        notes: crop.request_notes
      )
      expect(rendered).to have_content(expected_text)
    end
  end

  context 'when crop is rejected' do
    let(:crop) { build_stubbed(:rejected_crop, reason_for_rejection: 'not edible') }

    before do
      render partial: 'crops/approval_status_message', locals: { crop: }
    end

    it 'renders the localized rejection message' do
      expected_text = I18n.t(
        'crops.approval_status_message.rejected_message',
        reason: crop.rejection_explanation
      )
      expect(rendered).to have_content(expected_text)
    end
  end
end
