# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'growstuff:send_planting_reminder', flipper: :enable_planting_reminders do
  include ActiveJob::TestHelper

  before :all do
    Rails.application.load_tasks
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

  it 'enqueues a reminder on Monday' do
    expect { send_reminders }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  context 'when planting reminders are switched off', flipper: [] do
    it 'enqueues nothing' do
      expect { send_reminders }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end

  context 'when it is not Monday' do
    let(:day) { monday + 1.day }

    it 'enqueues nothing' do
      expect { send_reminders }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end
end
