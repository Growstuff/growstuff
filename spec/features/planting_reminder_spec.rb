require 'spec_helper'

feature "planting reminder" do
  before :each do
    @member = FactoryGirl.create(:member)
  end

  scenario "sends email" do
    expect {
      # stub for while we're working on this. remove!
      Notifier.planting_reminder(@member).deliver!
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
