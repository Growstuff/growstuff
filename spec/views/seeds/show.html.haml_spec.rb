# frozen_string_literal: true

require 'rails_helper'

describe "seeds/show" do
  let(:seed) { create(:seed) }

  before do
    controller.stub(:current_user) { nil }
    assign(:seed, seed)
    assign(:photos, seed.photos.paginate(page: 1))
    render
  end

  it "renders attributes in <p>" do
    expect(rendered).to have_content seed.crop.name
  end

  describe "the heirloom or hybrid fact" do
    context "when it is an heirloom" do
      let(:seed) { create(:seed, heirloom: 'heirloom') }

      it { expect(rendered).to have_css('.seedfacts--heirloom', text: 'Heirloom') }
      it { expect(rendered).to have_css('h3', text: 'Heirloom or hybrid') }
    end

    context "when it is a hybrid" do
      let(:seed) { create(:seed, heirloom: 'hybrid') }

      it { expect(rendered).to have_css('.seedfacts--heirloom', text: 'Hybrid') }
    end

    context "when it is not known" do
      let(:seed) { create(:seed, heirloom: 'unknown') }

      it { expect(rendered).to have_css('.seedfacts--heirloom', text: 'Unknown') }
      it { expect(rendered).to have_css('.card.text-muted .seedfacts--heirloom') }
    end
  end

  context "tradable" do
    context 'with location' do
      let!(:owner) { create(:london_member) }
      let!(:seed)   { create(:tradable_seed, owner:) }
      let!(:member) { create(:member) }

      before do
        assign(:seed, seed)
        # NOTE: current_member is not the owner of this seed
        sign_in member
        controller.stub(:current_user) { member }
        render
      end

      it "shows tradable attributes" do
        expect(rendered).to have_content "Will trade locally"
      end

      it "shows button to send message" do
        expect(rendered).to have_content "Request seeds"
      end

      describe "shows location of seed owner" do
        it { expect(rendered).to have_content owner.location }
        it { expect(rendered).to have_link seed.owner.location, href: place_path(seed.owner.location, anchor: "seeds") }
      end
    end

    context 'with no location' do
      # no location
      let(:owner) { create(:member) }
      let!(:seed) { create(:tradable_seed, owner:) }

      before do
        sign_in owner
        controller.stub(:current_user) { owner }
        assign(:seed, seed)
        render
      end

      it 'says "from unspecified location"' do
        expect(rendered).to have_content "(from unspecified location)"
      end

      it "links to profile to set location" do
        expect(rendered).to have_link("Set Location") # , href: edit_member_registration_path)
      end
    end
  end
end
