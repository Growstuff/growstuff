# frozen_string_literal: true

require 'rails_helper'

describe RegistrationsController, '#update' do
  let(:member) { create(:member, settings: { 'locale' => 'en' }) }
  let(:dimensions) { { label_width_mm: '62', label_height_mm: '29' } }

  before do
    sign_in member
    put member_registration_path, params: { member: dimensions }
  end

  it 'saves the preferred dimensions without a password' do
    expect(member.reload.settings.slice('label_width_mm', 'label_height_mm')).to eq(dimensions.stringify_keys)
  end

  it 'preserves other settings' do
    expect(member.reload.locale).to eq('en')
  end

  context 'with invalid dimensions' do
    let(:dimensions) { { label_width_mm: '0', label_height_mm: '29' } }

    it 'does not save the preference' do
      expect(member.reload.label_width_mm).to be_nil
    end
  end

  context 'when clearing a preference' do
    let(:member) { create(:member, label_width_mm: '62', label_height_mm: '29') }
    let(:dimensions) { { label_width_mm: '', label_height_mm: '' } }

    it 'clears the dimensions' do
      expect(member.reload.label_width_mm).to be_blank
    end
  end
end
