# frozen_string_literal: true

require 'rails_helper'

describe "harvests/show" do
  subject { render }

  let!(:harvest) { create(:harvest) }

  before do
    controller.stub(:current_user) { nil }
    assign(:harvest, harvest)
    assign(:photos, harvest.photos.paginate(page: 1))
    render
  end

  describe "renders attributes" do
    it { is_expected.to have_content harvest.crop.name }
    it { is_expected.to have_content I18n.l(harvest.harvested_at) }
    it { is_expected.to have_content harvest.plant_part.to_s }
    it { is_expected.to have_content I18n.t('harvests.show.heading', crop: harvest.crop.name.titleize) }
    it { is_expected.to have_content I18n.t('harvests.show.harvested_by') }
    it { is_expected.to have_content I18n.t('harvests.show.plant_part') }
    it { is_expected.to have_content I18n.t('harvests.show.harvested') }
    it { is_expected.to have_content I18n.t('harvests.show.quantity') }
    it { is_expected.to have_content I18n.t('harvests.show.photos') }
    it { is_expected.to have_content I18n.t('harvests.show.crop') }

    it 'renders localized active breadcrumb' do
      expect(view.content_for(:breadcrumbs)).to have_content I18n.t('harvests.show.breadcrumb')
    end
  end
end
