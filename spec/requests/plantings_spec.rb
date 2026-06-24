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

      @predictable_planting = create(:predictable_planting, owner: @member, planted_at: 1.day.ago, days_to_first_harvest: 10,
days_to_last_harvest: 20)
      @predictable_planting.crop.update(median_days_to_first_harvest: 10)

      @seedling_planting = create(:seedling_planting, owner: @member)
      @seed_planting = create(:seed_planting, owner: @member)
      @finished_planting = create(:finished_planting, owner: @member)
      @annual_planting = create(:annual_planting, owner: @member)
      @perennial_planting = create(:perennial_planting, owner: @member)
    end

    describe "GET /members/x/plantings.ics" do
      it "works!" do
        get member_plantings_path(@member, format: "ics")

        calendar = Icalendar::Parser.new(response.body, true).parse.first
        expect(calendar.description[0].to_s).to eq "Plantings by #{@member.login_name}"
        events = calendar.events
        expect(events.length).to eq 7

        # TODO: Better date comparison
        # Predicted finish should be used
        predictable_event = events.find { |e| e.dtend.to_date == @predictable_planting.finish_predicted_at }
        expect(predictable_event.summary.to_s).to include @predictable_planting.crop.name
        expect(predictable_event.dtstart.to_datetime.to_i).to be_within(1.second).of @predictable_planting.created_at.to_i

        # Actual finish should be used
        # expect(events[4].dtend.to_date).to be_within(1.second).of @finished_planting.finished_at

        # Otherwise, tomorrow should be used
        expect(events.map { |e| e.dtend.to_date }).to include 1.day.from_now.to_date

        # TBA: Perennial and annual crops predictions of 'next' harvest date don't really fit

        response.status.should be(200)
      end
    end

    describe "GET /members/x/plantings.csv" do
      let(:expected_headers) do
        [
          "Id",
          "Growstuff url",
          "Owner",
          "Owner name",
          "Garden",
          "Garden name",
          "Crop",
          "Crop name",
          "Quantity",
          "Planted from",
          "Sunniness",
          "Date planted",
          "Finished",
          "Date finished",
          "Description",
          "Date added",
          "Last modified",
          "License"
        ]
      end

      it "works!" do
        get member_plantings_path(@member, format: "csv")

        response.status.should be(200)

        data = CSV.parse(response.body, headers: true)
        expect(data.headers).to eq expected_headers

        row = data.detect { |crop_name| @predictable_planting.id.to_s == crop_name['Id'] }

        expect(row["Crop name"]).to eq @predictable_planting.crop.name
        expect(row["Owner name"]).to eq @member.to_s
        expect(row["Garden name"]).to eq @predictable_planting.garden.to_s
        expect(row["Description"]).to eq @predictable_planting.description
        expect(row["Date planted"]).to eq @predictable_planting.planted_at.to_fs(:db)
        expect(row["Quantity"].to_i).to eq @predictable_planting.quantity
        expect(row["Sunniness"]).to eq @predictable_planting.sunniness
        expect(row["Planted from"]).to eq @predictable_planting.planted_from
        expect(row["Date added"]).to eq @predictable_planting.created_at.to_fs(:db)
        expect(row["License"]).to eq "CC-BY-SA Growstuff http://growstuff.org/"

        expect(data.count).to eq 6
      end
    end
  end
end
