## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project
## We no longer write new view and controller tests, but instead write
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara).
## These test the full stack, behaving as a browser, and require less complicated setup
## to run. Please feel free to delete old view/controller tests as they are reimplemented
## in feature tests.
##
## If you submit a pull request containing new view or controller tests, it will not be
## merged.

require 'rails_helper'

describe "crops/_planting_advice" do
  let(:planting) { FactoryBot.create(:planting) }
  subject { rendered }

  shared_examples "render planting_advice" do
    before { render 'crops/planting_advice', crop: planting.crop }
  end

  describe "sunniness" do
    context "with no sunniness set" do
      include_examples "render planting_advice"
      it "doesn't show sunniness" do
        is_expected.to have_content "Plant in: not known."
      end
    end

    context "with sunniness frequencies" do
      before { FactoryBot.create(:sunny_planting, crop: planting.crop) }
      include_examples "render planting_advice"
      it { is_expected.to have_content "Plant in:" }
      it { is_expected.to have_content "sun (1)" }
    end

    context "with multiple sunniness frequencies" do
      before do
        FactoryBot.create_list(:sunny_planting, 2, crop: planting.crop)
        FactoryBot.create(:shady_planting, crop: planting.crop)
      end
      include_examples "render planting_advice"
      it { is_expected.to have_content "Plant in:" }
      it { is_expected.to have_content "sun (2), shade (1)" }
    end
  end

  describe "planted from" do
    context "when none are set" do
      include_examples "render planting_advice"
      it "doesn't show planted_from " do
        is_expected.to have_content "Plant from: not known."
      end
    end

    context "with planted_from frequencies" do
      before { FactoryBot.create(:seed_planting, crop: planting.crop) }
      include_examples "render planting_advice"
      it { is_expected.to have_content "Plant from:" }
      it { is_expected.to have_content "seed (1)" }
    end

    context "with multiple planted_from frequencies" do
      before do
        FactoryBot.create_list(:seed_planting, 2, crop: planting.crop)
        FactoryBot.create(:cutting_planting, crop: planting.crop)
      end
      include_examples "render planting_advice"
      it { is_expected.to have_content "Plant from:" }
      it { is_expected.to have_content "seed (2), cutting (1)" }
    end
  end
end
