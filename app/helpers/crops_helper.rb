# frozen_string_literal: true

module CropsHelper
  def display_seed_availability(member, crop)
    seeds = member.seeds.where(crop:)
    total_quantity = seeds.where.not(quantity: nil).sum(:quantity)

    return "You don't have any seeds of this crop." if seeds.none?

    if total_quantity == 0
      "You have an unknown quantity of seeds of this crop."
    else
      "You have #{total_quantity} #{Seed.model_name.human(count: total_quantity)} of this crop."
    end
  end

  def crop_ebay_seeds_url(crop)
    "https://www.ebay.com/sch/i.html?_nkw=#{CGI.escape crop.name}"
  end
end
