# frozen_string_literal: true

require 'rails_helper'

describe ReminderService do
  let(:member) { create(:member, send_planting_reminder: true, send_harvest_reminder: true) }
  let(:bot) { create(:cropbot) }
  let(:service) { ReminderService.new }

  before do
    allow(Member).to receive(:find_by).with(login_name: 'cropbot').and_return(bot)
    member.confirm
  end

  describe "#send_planting_reminders" do
    context "on Monday" do
      before do
        Timecop.freeze(Time.zone.parse("2025-05-19")) # A Monday
      end

      after do
        Timecop.return
      end

      it "creates a notification if member has active plantings" do
        create(:planting, owner: member)
        expect {
          service.send_planting_reminders
        }.to change(Notification, :count).by(1)
      end

      it "does not create a notification if member has no active plantings" do
        expect {
          service.send_planting_reminders
        }.not_to change(Notification, :count)
      end
    end

    context "not on Monday" do
      before do
        Timecop.freeze(Time.zone.parse("2025-05-20")) # A Tuesday
      end

      after do
        Timecop.return
      end

      it "does nothing" do
        create(:planting, owner: member)
        expect {
          service.send_planting_reminders
        }.not_to change(Notification, :count)
      end
    end
  end

  describe "#send_harvest_reminders" do
    context "on Wednesday" do
      before do
        Timecop.freeze(Time.zone.parse("2025-05-21")) # A Wednesday
      end

      after do
        Timecop.return
      end

      it "creates a notification if member has plantings ready to harvest" do
        planting = create(:planting, owner: member)
        # Mock harvest_in_next_week?
        allow_any_instance_of(Planting).to receive(:harvest_in_next_week?).and_return(true)

        expect {
          service.send_harvest_reminders
        }.to change(Notification, :count).by(1)
      end

      it "does not create a notification if no plantings are ready" do
        create(:planting, owner: member)
        allow_any_instance_of(Planting).to receive(:harvest_in_next_week?).and_return(false)

        expect {
          service.send_harvest_reminders
        }.not_to change(Notification, :count)
      end
    end
  end
end
