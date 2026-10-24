# frozen_string_literal: true

require 'rails_helper'

describe JobsController, '#index with ideas' do
  let(:member) { create(:member) }
  let(:page) { Capybara.string(response.body) }

  before do
    Rails.cache.clear
    sign_in member
  end

  context 'when there are ideas' do
    before do
      create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.current - 1.year + 2.days)
      get member_jobs_path(member)
    end

    it 'says so in a yellow box over the jobs' do
      expect(page).to have_css('.notepad-ideas', text: 'We have 1 suggested job for you this week')
    end

    it 'has the overlay the links open' do
      expect(page).to have_css('#job-ideas-modal #job-ideas-body', visible: :all)
    end

    it 'links the box to the ideas' do
      expect(page).to have_link(href: '/job_ideas', class: 'notepad-ideas')
    end
  end

  context 'when member has a location and forecast data' do
    let(:located_member) { create(:london_member) }

    before do
      allow(WeatherService).to receive(:forecast_for).with(located_member).and_return(
        WeatherService::Forecast.new(
          {
            'daily' => {
              'time' => [Date.current.to_s],
              'weather_code' => [0],
              'temperature_2m_max' => [22.0],
              'temperature_2m_min' => [12.0],
              'precipitation_sum' => [0.0],
              'precipitation_probability_max' => [0],
              'wind_speed_10m_max' => [10.0]
            }
          },
          'celsius'
        )
      )
      sign_in located_member
      get member_jobs_path(located_member)
    end

    it 'renders the weather description and details modal' do
      expect(page).to have_css('.weather-summary', text: '22°C / 12°C, Clear sky')
      expect(page).to have_css('#weather-modal-today', visible: :all)
      expect(page).to have_link('Learn more on Open-Meteo', href: 'https://open-meteo.com/en/licence')
    end
  end

  context 'when there are none' do
    before { get member_jobs_path(member) }

    it 'has no box of links beside the jobs' do
      expect(page).to have_no_css('nav[aria-label="Jobs"]')
    end

    it 'has no open data box beside the jobs' do
      expect(page).to have_no_css('.open-data')
    end

    it 'takes the whole width for the jobs' do
      expect(page).to have_css('.col-12 .notepad')
    end

    it 'shows no yellow box' do
      expect(page).to have_no_css('.notepad-ideas')
    end
  end
end
