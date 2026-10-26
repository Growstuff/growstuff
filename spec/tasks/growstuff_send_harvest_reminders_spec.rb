# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'growstuff:send_harvest_reminders', flipper: :enable_harvest_reminders do
  before :all do
    Rails.application.load_tasks unless Rake::Task.task_defined?('growstuff:send_harvest_reminders')
  end

  before do
    Rake::Task['growstuff:send_harvest_reminders'].reenable
  end

  it "sends harvest reminders on Wednesday for members with active plantings due next week" do
    wednesday = Time.zone.today.beginning_of_week + 2.days
    allow(Time.zone).to receive(:today).and_return(wednesday)

    member = create(:member, send_harvest_reminder: true, confirmed_at: 1.day.ago)
    crop = create(:crop, median_days_to_first_harvest: 20)
    create(:planting, owner: member, crop: crop, planted_at: wednesday - 15.days)

    expect do
      Rake::Task['growstuff:send_harvest_reminders'].invoke
    end.to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it "does not send harvest reminders on non-Wednesdays" do
    monday = Time.zone.today.beginning_of_week
    allow(Time.zone).to receive(:today).and_return(monday)

    member = create(:member, send_harvest_reminder: true, confirmed_at: 1.day.ago)
    crop = create(:crop, median_days_to_first_harvest: 20)
    create(:planting, owner: member, crop: crop, planted_at: monday - 15.days)

    expect do
      Rake::Task['growstuff:send_harvest_reminders'].invoke
    end.not_to(change { ActionMailer::Base.deliveries.count })
  end

  it "does not send harvest reminders when they are switched off", flipper: [] do
    wednesday = Time.zone.today.beginning_of_week + 2.days
    allow(Time.zone).to receive(:today).and_return(wednesday)

    member = create(:member, send_harvest_reminder: true, confirmed_at: 1.day.ago)
    crop = create(:crop, median_days_to_first_harvest: 20)
    create(:planting, owner: member, crop: crop, planted_at: wednesday - 15.days)

    expect do
      Rake::Task['growstuff:send_harvest_reminders'].invoke
    end.not_to(change { ActionMailer::Base.deliveries.count })
  end
end
