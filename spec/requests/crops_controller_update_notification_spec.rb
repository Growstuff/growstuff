# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#update notifying the requester' do
  let(:requester) { create(:member) }
  let(:crop) { create(:crop_request, requester:) }
  let(:params) { { approve: 'Approve' } }

  before do
    allow_any_instance_of(Crop).to receive(:update_gbif_data!) # rubocop:disable RSpec/AnyInstance
    sign_in create(:crop_wrangling_member)
  end

  def update_crop
    put crop_path(crop), params: { crop: { name: crop.name }.merge(extra_crop_params) }.merge(params)
  end

  let(:extra_crop_params) { {} }

  def delivered_to(member)
    ActionMailer::Base.deliveries.select { |mail| mail.to == [member.email] }
  end

  context 'when approving' do
    before { update_crop }

    it 'emails the requester' do
      expect(delivered_to(requester).map(&:subject)).to eq ["#{crop.name.capitalize} has been approved"]
    end
  end

  context 'when rejecting' do
    let(:params) { { reject: 'Reject' } }
    let(:extra_crop_params) { { reason_for_rejection: 'Not a real plant' } }

    before { update_crop }

    it 'emails the requester' do
      expect(delivered_to(requester).map(&:subject)).to eq ["#{crop.name.capitalize} has been rejected"]
    end
  end

  context 'when the crop has no requester' do
    let(:requester) { nil }

    it 'approves without raising' do
      update_crop
      expect(crop.reload.approval_status).to eq 'approved'
    end
  end
end
