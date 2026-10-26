# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject(:ability) { described_class.new(member) }

  let(:member) { create(:member) }

  describe 'uploading photos' do
    context 'without access' do
      it { is_expected.not_to be_able_to(:upload, Photo) }
    end

    context 'with a request waiting' do
      before { create(:photo_library_access, member:) }

      it { is_expected.not_to be_able_to(:upload, Photo) }
    end

    context 'with approved access' do
      before { create(:approved_photo_library_access, member:) }

      it { is_expected.to be_able_to(:upload, Photo) }
    end

    context 'with revoked access' do
      before { create(:approved_photo_library_access, member:).revoke!(create(:admin_member)) }

      it { is_expected.not_to be_able_to(:upload, Photo) }
    end

    context 'with an admin' do
      let(:member) { create(:admin_member) }

      it { is_expected.to be_able_to(:upload, Photo) }
    end
  end

  describe 'linking a photo hosted elsewhere' do
    it { is_expected.to be_able_to(:create, Photo) }
  end

  describe 'photo library access' do
    it 'lets a member ask for themselves' do
      expect(ability).to be_able_to(:create, PhotoLibraryAccess.new(member:))
    end

    it 'does not let a member ask for someone else' do
      expect(ability).not_to be_able_to(:create, PhotoLibraryAccess.new(member: create(:member)))
    end

    it "hides other members' requests" do
      expect(ability).not_to be_able_to(:read, create(:photo_library_access))
    end
  end
end
