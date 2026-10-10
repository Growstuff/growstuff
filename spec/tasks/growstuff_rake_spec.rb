# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'growstuff:reminders' do
  before :all do
    Rails.application.load_tasks
  end

  let(:planting_task) { Rake::Task['growstuff:send_planting_reminder'] }
  let(:harvest_task) { Rake::Task['growstuff:send_harvest_reminders'] }

  before do
    planting_task.reenable
    harvest_task.reenable
  end

  it "calls ReminderService for planting reminders" do
    expect_any_instance_of(ReminderService).to receive(:send_planting_reminders)
    planting_task.invoke
  end

  it "calls ReminderService for harvest reminders" do
    expect_any_instance_of(ReminderService).to receive(:send_harvest_reminders)
    harvest_task.invoke
  end
end
