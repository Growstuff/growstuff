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
      @member.plantings << build(:predictable_planting)
      @member.plantings << build(:seedling_planting)
      @member.plantings << build(:seed_planting)
      @member.plantings << build(:finished_planting)
      @member.plantings << build(:annual_planting)
      @member.plantings << build(:perennial_planting)

      Planting.reindex
    end

    describe "GET /members/x/plantings.ics" do
      it "works!" do
        get member_plantings_path(@member, format: "ics")

        calendar = Icalendar::Parser.new(response.body, true).parse.first
        expect(calendar.description).to eq "Plantings by #{@member.login_name}"
        events = calendar.events
        expect(events.length).to eq 6

        predictable
        # TODO: Better date comparison
        expect(events[0].dtstart.to_datetime.to_i).to be_within(1.second).of @planting.created_at.to_i
        expect(events[0].description).to include_text @planting.crop.name

        response.status.should be(200)
      end
    end
  end
end
