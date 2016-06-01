require 'rails_helper'

describe SeedsHelper do
  describe "seed description" do
    it "is missing" do
      seed = FactoryGirl.create(:seed,
        description: nil
      )
      result = helper.display_seed_description(seed)
      expect(result).to eq "no description provided."
    end

    it "is less than 130 characters long" do
      seed = FactoryGirl.create(:seed,
        description: 'a' * 20
      )
      result = helper.display_seed_description(seed)
      expect(result).to eq 'a' * 20
    end

    it "is 130 characters long" do
      seed = FactoryGirl.create(:seed,
        description: 'a' * 130
      )
      result = helper.display_seed_description(seed)
      link = link_to("Read more", seed_path(seed))
      expect(result).to eq 'a' * 130
    end

    it "is more than 130 characters long" do
      seed = FactoryGirl.create(:seed,
        description: 'a' * 140
      )
      result = helper.display_seed_description(seed)
      expect(result).to eq 'a' * 126 + '...' + ' ' + link_to("Read more", seed_path(seed))
    end
  end
end
