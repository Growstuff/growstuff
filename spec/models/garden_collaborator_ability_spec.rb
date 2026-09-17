# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  let(:member) { create(:member) }
  let(:ability) { described_class.new(member) }

  context 'garden collaborators' do
    let(:garden) { create(:garden) }
    let(:garden_collaborator) { create(:garden_collaborator, garden: garden, member: member) }
    let(:other_member) { create(:member) }
    let(:other_garden_collaborator) { create(:garden_collaborator, garden: garden, member: other_member) }

    it 'can remove themselves as a collaborator' do
      expect(ability).to be_able_to(:destroy, garden_collaborator)
    end

    it 'cannot remove others as a collaborator if not garden owner' do
      expect(ability).not_to be_able_to(:destroy, other_garden_collaborator)
    end

    context 'as garden owner' do
      let(:garden) { create(:garden, owner: member) }

      it 'can remove others as a collaborator' do
        expect(ability).to be_able_to(:destroy, other_garden_collaborator)
      end
    end
  end
end
