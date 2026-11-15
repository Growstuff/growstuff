# frozen_string_literal: true

require 'rails_helper'

describe StallRecipients do
  subject(:recipients) { described_class.new(member) }

  let(:member) { create_located_member('Wellington, New Zealand', -41.29, 174.78) }

  describe '#suggestions' do
    let(:names) { recipients.suggestions.pluck(:name) }

    before do
      far = create_located_member('Toronto, Canada', 43.65, -79.38)
      member.follows.create!(followed: far)
      create_located_member('Lower Hutt, New Zealand', -41.21, 174.91, login_name: 'hutt')
      create_located_member('Melbourne, Australia', -37.81, 144.96, login_name: 'melbourne')
      create_located_member('Karori, New Zealand', -41.28, 174.75, login_name: 'karori')
      create_located_member('Newtown, New Zealand', -41.31, 174.78, login_name: 'newtown')
    end

    it 'shows three people' do
      expect(names.size).to eq 3
    end

    it 'shows the nearest first, even over someone followed' do
      expect(names).to eq %w(newtown karori hutt)
    end

    it 'leaves out the member themself' do
      expect(names).not_to include(member.login_name)
    end
  end

  describe '#search' do
    before { create_list(:member, 5).each_with_index { |person, index| person.update!(login_name: "sam_#{index}") } }

    it 'shows three people' do
      expect(recipients.search('sam').size).to eq 3
    end
  end
end
