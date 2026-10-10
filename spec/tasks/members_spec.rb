# frozen_string_literal: true

require 'rails_helper'
require 'rake'

describe 'members:cleanup_inactive' do
  before :all do
    Rails.application.load_tasks
  end

  let(:cleanup_task) { Rake::Task['members:cleanup_inactive'] }

  before do
    cleanup_task.reenable
  end

  it "deletes inactive members with no gardens and no other activity" do
    inactive_no_activity = create(:member, last_sign_in_at: 25.months.ago)

    # We must explicitly remove the default garden to test the "no gardens" condition
    inactive_no_activity.gardens.destroy_all
    expect(inactive_no_activity.gardens.count).to eq(0)

    cleanup_task.invoke

    expect(Member.exists?(inactive_no_activity.id)).to be_falsey
  end

  it "does not delete inactive members with a garden (even if empty)" do
    inactive_with_garden = create(:member, last_sign_in_at: 25.months.ago)
    # They have 1 default garden
    expect(inactive_with_garden.gardens.count).to eq(1)

    cleanup_task.invoke

    expect(Member.exists?(inactive_with_garden.id)).to be_truthy
  end

  it "does not delete members with recent login" do
    recent_member = create(:member, last_sign_in_at: 1.month.ago)
    recent_member.gardens.destroy_all

    cleanup_task.invoke

    expect(Member.exists?(recent_member.id)).to be_truthy
  end

  it "does not delete inactive members with activity (posts)" do
    inactive_with_post = create(:member, last_sign_in_at: 25.months.ago)
    inactive_with_post.gardens.destroy_all
    create(:post, author: inactive_with_post)

    cleanup_task.invoke

    expect(Member.exists?(inactive_with_post.id)).to be_truthy
  end

  it "honors DRY_RUN environment variable" do
    inactive_no_activity = create(:member, last_sign_in_at: 25.months.ago)
    inactive_no_activity.gardens.destroy_all

    ENV['DRY_RUN'] = 'true'
    cleanup_task.invoke
    ENV['DRY_RUN'] = nil

    expect(Member.exists?(inactive_no_activity.id)).to be_truthy
  end
end
