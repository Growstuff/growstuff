# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SoilPhReadingsController do
  include Devise::Test::IntegrationHelpers

  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }
  let(:attributes) { { ph: '6.75', measured_on: '2026-10-01' } }

  def record_reading(values = attributes)
    post garden_soil_ph_readings_path(garden), params: { soil_ph_reading: values }
  end

  context 'when signed in as the owner' do
    before { sign_in owner }

    %i(en de es fr ja zh).each do |locale|
      context "with the #{locale} locale" do
        it 'renders the translated form and measurement guidance' do
          get new_garden_soil_ph_reading_path(garden), params: { locale: locale }
          title = I18n.t('soil_ph_readings.measuring_title', locale: locale, fallback: false, raise: true)
          expect(Capybara.string(response.body)).to have_css('details summary', text: title)
        end

        it 'has all feature translations' do
          keys = I18n.t('soil_ph_readings', locale: :en).keys
          expect(keys.all? { |key| I18n.exists?("soil_ph_readings.#{key}", locale, fallback: false) }).to be true
        end

        it 'translates validation field names' do
          translated = %i(ph measured_on).all? do |key|
            I18n.exists?("activerecord.attributes.soil_ph_reading.#{key}", locale, fallback: false)
          end
          expect(translated).to be true
        end
      end
    end

    it 'records the value and measurement date' do
      record_reading
      expect(garden.soil_ph_readings.last).to have_attributes(ph: BigDecimal('6.75'), measured_on: Date.new(2026, 10, 1))
    end

    it 'returns to the garden history' do
      record_reading
      expect(response).to redirect_to(garden_path(garden, anchor: 'soil-ph'))
    end

    it 'allows multiple measurements in the same month' do
      record_reading
      expect { record_reading }.to change(garden.soil_ph_readings, :count).by(1)
    end

    it 'shows invalid values for correction' do
      record_reading(attributes.merge(ph: 15))
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'does not save invalid readings' do
      expect { record_reading(attributes.merge(ph: 15)) }.not_to change(SoilPhReading, :count)
    end

    it 'defaults the form date to today' do
      get new_garden_soil_ph_reading_path(garden)
      expect(Capybara.string(response.body)).to have_css("input[type='date'][value='#{Time.zone.today}']")
    end

    it 'offers a modal on the garden page' do
      get garden_path(garden)
      expect(Capybara.string(response.body)).to have_css('#soil-ph-modal form', visible: :all)
    end
  end

  context 'when signed in as a collaborator' do
    let(:collaborator) { create(:member) }

    before do
      create(:garden_collaborator, garden:, member: collaborator)
      sign_in collaborator
    end

    it 'records a reading' do
      expect { record_reading }.to change(garden.soil_ph_readings, :count).by(1)
    end
  end

  context 'when signed in as another member' do
    before { sign_in create(:member) }

    it 'does not record a reading' do
      expect { record_reading }.not_to change(SoilPhReading, :count)
    end
  end

  context 'when signed out' do
    it 'requires sign in' do
      record_reading
      expect(response).to redirect_to(new_member_session_path)
    end

    it 'shows readings newest first' do
      garden.soil_ph_readings.create!(ph: 6.1, measured_on: Date.new(2026, 9, 1))
      garden.soil_ph_readings.create!(ph: 6.8, measured_on: Date.new(2026, 10, 1))
      get garden_path(garden)
      expect(Capybara.string(response.body).all('#soil-ph tbody tr').map { |row| row.all('td').last.text }).to eq(['6.8', '6.1'])
    end

    it 'hides the modal' do
      get garden_path(garden)
      expect(Capybara.string(response.body)).to have_no_css('#soil-ph-modal', visible: :all)
    end
  end
end
