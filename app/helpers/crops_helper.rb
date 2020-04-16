# frozen_string_literal: true

module CropsHelper
  def display_seed_availability(member, crop)
    seeds = member.seeds.where(crop: crop)
    total_quantity = seeds.where.not(quantity: nil).sum(:quantity)

    return "You don't have any seeds of this crop." if seeds.none?

    if total_quantity != 0
      "You have #{total_quantity} #{Seed.model_name.human(count: total_quantity)} of this crop."
    else
      "You have an unknown quantity of seeds of this crop."
    end
  end

  def crop_ebay_seeds_url(crop)
    "https://rover.ebay.com/rover/1/705-53470-19255-0/1?icep_ff3=9&pub=5575213277&toolid=10001&campid=5337940151&customid=&icep_uq=#{CGI.escape crop.name}&icep_sellerId=&icep_ex_kw=&icep_sortBy=12&icep_catId=181003&icep_minPrice=&icep_maxPrice=&ipn=psmain&icep_vectorid=229515&kwid=902099&mtid=824&kw=lg"
  end
end
