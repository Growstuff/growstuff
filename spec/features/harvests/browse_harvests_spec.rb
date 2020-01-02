# frozen_string_literal: true

require 'rails_helper'

describe "browse harvests", :search do
  subject { page }

  let!(:harvest) { create :harvest, owner: member }

  context 'signed in' do
    include_context 'signed in member'

    describe 'blank optional fields' do
      let!(:harvest) { create :harvest, :no_description, :reindex }

      before do
        Harvest.reindex
        visit harvests_path
      end

      it 'read more' do
        expect(subject).not_to have_link "Read more"
      end
    end

    describe "filled in optional fields" do
      let!(:harvest) { create :harvest, :long_description, :reindex }

      before do
        Harvest.reindex
        visit harvests_path
      end

      it 'links to #show' do
        expect(subject).to have_link harvest.crop.name, href: harvest_path(harvest)
      end
    end
  end
end
