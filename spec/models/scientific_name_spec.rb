# frozen_string_literal: true

require 'rails_helper'

describe ScientificName do
  context 'all fields present' do
    let(:sn) { create(:zea_mays) }

    it 'saves a basic scientific name' do
      expect(sn.save).to be(true)
    end

    it 'is fetchable from the database' do
      sn.save
      @sn2 = described_class.find_by(name: 'Zea mays')
      expect(@sn2.crop.name).to == 'maize'
    end

    it 'has a creator' do
      sn.save
      expect(sn.creator).to be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'does not save a scientific name without a name' do
      sn = described_class.new
      expect { sn.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
