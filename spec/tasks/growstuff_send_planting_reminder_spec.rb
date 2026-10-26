# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'growstuff:send_planting_reminder', flipper: :enable_planting_reminders do
  before :all do
    Rails.application.load_tasks unless Rake::Task.task_defined?('growstuff:send_planting_reminder')
  end

  before do
    Rake::Task['growstuff:send_planting_reminder'].reenable
    allow(Time.zone).to receive(:today).and_return(day)
    create(:planting, owner: member)
  end

  let(:monday) { Time.zone.today.beginning_of_week }
  let(:day) { monday }
  let(:member) { create(:member, send_planting_reminder: true, confirmed_at: 1.day.ago) }

  def send_reminders
    Rake::Task['growstuff:send_planting_reminder'].invoke
  end

  it 'sends a reminder on Monday' do
    expect { send_reminders }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  context 'when planting reminders are switched off', flipper: [] do
    it 'sends nothing' do
      expect { send_reminders }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end

  context 'when it is not Monday' do
    let(:day) { monday + 1.day }

    it 'sends nothing' do
      expect { send_reminders }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
