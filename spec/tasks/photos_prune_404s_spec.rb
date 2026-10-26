# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'photos:prune_404s' do
  before :all do
    Rails.application.load_tasks unless Rake::Task.task_defined?('photos:prune_404s')
  end

  before do
    Rake::Task['photos:prune_404s'].reenable
    allow(Time.zone).to receive(:today).and_return(day)
  end

  let(:first_of_month) { Date.new(2025, 5, 1) }
  let(:second_of_month) { Date.new(2025, 5, 2) }

  def prune_404s
    Rake::Task['photos:prune_404s'].invoke
  end

  context 'when today is the 1st of the month' do
    let(:day) { first_of_month }

    it 'checks photos and removes broken ones' do
      photo = create(:photo)
      response = instance_double(Net::HTTPNotFound, code: '404')
      http = instance_double(Net::HTTP)

      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(response)

      expect { prune_404s }.to change(Photo, :count).by(-1)
    end
  end

  context 'when today is not the 1st of the month' do
    let(:day) { second_of_month }

    it 'does not check or remove photos' do
      photo = create(:photo)

      expect(Net::HTTP).not_to receive(:new)
      expect { prune_404s }.not_to change(Photo, :count)
    end
  end
end
