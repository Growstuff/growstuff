# frozen_string_literal: true

require 'rails_helper'

describe PlantingHistory do
  subject(:history) { build(:planting_history) }

  it { is_expected.to be_valid }

  it 'needs the day the planting left the garden' do
    history.ended_on = nil
    expect(history).not_to be_valid
  end

  it 'goes when its planting does' do
    history.save!
    expect { history.planting.destroy }.to change(described_class, :count).by(-1)
  end
end
