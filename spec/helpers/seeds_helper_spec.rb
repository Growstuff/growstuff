require 'rails_helper'

describe SeedsHelper do
  describe "display_seed_description" do
    it "no description" do
      seed = FactoryGirl.create(:seed,
        description: nil
      )
      result = helper.display_seed_description(seed)
      expect(result).to eq "no description provided."
    end

    it "description is less than 130 chars" do
      seed = FactoryGirl.create(:seed,
        description: 'a' * 20
      )
      result = helper.display_seed_description(seed)
      expect(result).to eq 'a' * 20
    end

    it "description is 130 chars" do
      seed = FactoryGirl.create(:seed,
        description: 'a' * 130
      )
      result = helper.display_seed_description(seed)
      link = link_to("Read more", seed_path(seed))
      expect(result).to eq 'a' * 130
    end

    it "description is more than 130 chars" do
      seed = FactoryGirl.create(:seed,
        description: 'a' * 140
      )
      result = helper.display_seed_description(seed)
      expect(result).to eq 'a' * 126 + '...' + ' ' + link_to("Read more", seed_path(seed))
    end
  end
end
