# frozen_string_literal: true

require 'rails_helper'

describe "members/_contact" do
  context "when member has a website url" do
    context "without plantings" do
      let(:member) { create(:member, website_url: "https://example.com") }

      before do
        render partial: 'members/contact', locals: { member:, flickr_auth: nil }
      end

      it "renders website link with rel nofollow" do
        expect(rendered).to have_link("Website", href: "https://example.com", rel: "noopener noreferrer nofollow")
      end
    end

    context "with plantings" do
      let(:member) { create(:member, website_url: "https://example.com") }

      before do
        create(:planting, owner: member)
        render partial: 'members/contact', locals: { member:, flickr_auth: nil }
      end

      it "renders website link without rel nofollow" do
        expect(rendered).to have_link("Website", href: "https://example.com", rel: "noopener noreferrer")
      end
    end
  end
end
