# frozen_string_literal: true

require 'rails_helper'

describe CropsController, '#update growing facts' do
  let(:crop) { create(:tomato) }
  let(:params) do
    { crop: { germination_days_min: 5, germination_days_max: 10, days_until_maturity_min: 60, days_until_maturity_max: 80,
              sow_months: ['', '9', '10', '11'] } }
  end

  context 'when signed in as a crop wrangler' do
    before do
      sign_in create(:crop_wrangling_member)
      put crop_path(crop), params:
    end

    it { expect(crop.reload.germination_days_min).to eq 5 }
    it { expect(crop.reload.germination_days_max).to eq 10 }
    it { expect(crop.reload.days_until_maturity_min).to eq 60 }
    it { expect(crop.reload.days_until_maturity_max).to eq 80 }
    it { expect(crop.reload.sow_months).to eq [9, 10, 11] }
  end

  context 'when editing as a crop wrangler' do
    before do
      sign_in create(:crop_wrangling_member)
      get edit_crop_path(crop)
    end

    it { expect(Capybara.string(response.body)).to have_field('Germination, at least (days)') }
    it { expect(Capybara.string(response.body)).to have_field('Days until maturity, at most') }
    it { expect(Capybara.string(response.body)).to have_css('input[name="crop[sow_months][]"][value="9"]', visible: :all) }
  end
end
