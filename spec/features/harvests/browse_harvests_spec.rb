require 'rails_helper'

describe 'browse harvests' do
  subject { page }

  let!(:harvest) { create :harvest, owner: member }

  context 'signed in' do
    include_context 'signed in member'
    describe 'blank optional fields' do
      let!(:harvest) { create :harvest, :no_description }

      before { visit harvests_path }

      it 'read more' do
        expect(subject).not_to have_link 'Read more'
      end
    end

    describe 'filled in optional fields' do
      let!(:harvest) { create :harvest, :long_description }

      before { visit harvests_path }

      it 'links to #show' do
        expect(subject).to have_link harvest.crop.name, href: harvest_path(harvest)
      end
    end
  end
end
