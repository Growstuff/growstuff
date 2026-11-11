# frozen_string_literal: true

require 'rails_helper'

describe 'garden_collaborators/index' do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner: owner) }
  let(:collaborator_member) { create(:member) }
  let(:collaborator) { create(:garden_collaborator, garden: garden, member: collaborator_member) }

  before do
    sign_in owner
    allow(controller).to receive(:current_user).and_return(owner)
    allow(view).to receive(:current_member).and_return(owner)
    assign(:garden, garden)
    assign(:owner, owner)
  end

  context 'when there are no collaborators' do
    before do
      collaborators = GardenCollaborator.none.paginate(page: 1)
      assign(:garden_collaborators, collaborators)
      render
    end

    it 'displays empty message' do
      expect(rendered).to include(I18n.t('garden_collaborators.index.no_collaborators'))
    end
  end

  context 'when collaborators exist' do
    before do
      collaborator
      collaborators = garden.garden_collaborators.paginate(page: 1)
      assign(:garden_collaborators, collaborators)
      render
    end

    it 'displays the collaborator member login' do
      expect(rendered).to include(collaborator_member.login_name)
    end
  end
end
