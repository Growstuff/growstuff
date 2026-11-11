# frozen_string_literal: true

require 'rails_helper'

describe 'garden_collaborators/new' do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner: owner) }
  let(:garden_collaborator) { GardenCollaborator.new(garden: garden) }

  before do
    sign_in owner
    allow(controller).to receive(:current_user).and_return(owner)
    assign(:garden, garden)
    assign(:garden_collaborator, garden_collaborator)
    render
  end

  it 'renders new garden collaborator form' do
    assert_select 'form' do
      assert_select 'input#garden_collaborator_member_slug', name: 'garden_collaborator[member_slug]'
    end
  end

  it 'sets page title' do
    expect(view.content_for(:title)).to eq(I18n.t('garden_collaborators.new.title'))
  end
end
