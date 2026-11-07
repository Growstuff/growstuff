# frozen_string_literal: true

require 'rails_helper'

describe SessionsController do
  let(:password) { 'password1234' }
  let(:member) { create(:member, password:, password_confirmation: password) }

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before do
    allow(Feature).to receive(:enabled?).and_call_original
    allow(Feature).to receive(:enabled?).with(:planting_weather).and_return(true)
  end

  def log_in(password_to_use = password)
    post member_session_path, params: { member: { login: member.login_name, password: password_to_use } }
  end

  it 'queues a backfill for the signed-in member' do
    expect { log_in }.to have_enqueued_job(BackfillMemberWeatherJob).with(member.id)
  end

  it 'does not queue another backfill when restoring the session' do
    log_in
    expect { get root_path }.not_to have_enqueued_job(BackfillMemberWeatherJob)
  end

  it 'does not queue a backfill for a failed login' do
    expect { log_in('wrong-password') }.not_to have_enqueued_job(BackfillMemberWeatherJob)
  end

  context 'without the weather feature' do
    before { allow(Feature).to receive(:enabled?).with(:planting_weather).and_return(false) }

    it 'does not queue a backfill' do
      expect { log_in }.not_to have_enqueued_job(BackfillMemberWeatherJob)
    end
  end
end
