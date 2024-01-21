# frozen_string_literal: true

require 'rails_helper'

describe "Plantings" do
  describe "GET /plantings" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get plantings_path
      response.status.should be(200)
    end
  end

  context "with a member" do
    before do
      @member = create(:interesting_member)
      @predictable_planting = create(:predictable_planting, owner: @member)
      @seedling_planting = create(:seedling_planting, owner: @member)
      @seed_planting = create(:seed_planting, owner: @member)
      @finished_planting = create(:finished_planting, owner: @member)
      @annual_planting = create(:annual_planting, owner: @member)
      @perennial_planting = create(:perennial_planting, owner: @member)

      Planting.reindex
    end

    describe "GET /members/x/plantings.ics" do
      it "works!" do
        get member_plantings_path(@member, format: "ics")

        calendar = Icalendar::Parser.new(response.body, true).parse.first
        expect(calendar.description[0].to_s).to eq "Plantings by #{@member.login_name}"
        events = calendar.events
        expect(events.length).to eq 6 # There are 7, but finished plantings aren't included

        # TODO: Better date comparison
        # Predicted finish should be used
        expect(events[1].summary.to_s).to include @predictable_planting.crop.name
        expect(events[1].dtstart.to_datetime.to_i).to be_within(1.second).of @predictable_planting.created_at.to_i
        expect(events[1].dtend.to_date).to eq @predictable_planting.finish_predicted_at

        # Actual finish should be used
        # expect(events[4].dtend.to_date).to be_within(1.second).of @finised_planting.finished_at

        # Otherwise, tomorrow should be used
        expect(events[2].dtend.to_date).to eq 1.day.from_now.to_date

        # TBA: Perennial and annual crops predictions of 'next' harvest date don't really fit

        response.status.should be(200)
      end
    end
  end
end
