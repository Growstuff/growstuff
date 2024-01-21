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
      @planting = @member.plantings.first

      Planting.reindex
    end

    describe "GET /members/x/plantings.ics" do
      it "works!" do
        get member_plantings_path(@member, format: "ics")

        calendar = Icalendar::Parser.new(response.body, true).parse.first
        events = calendar.events
        expect(events.length).to eq 1
        # TODO: Better date comparison
        expect(events[0].dtstart.to_datetime.to_i).to be_within(1.second).of @planting.created_at.to_i
        # expect(events[0].dtstart).to eq @planting.created_at
        # expect(events[0].dtstart).to eq @planting.created_at

        response.status.should be(200)
      end
    end
  end
end
