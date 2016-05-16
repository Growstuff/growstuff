module CropsHelper
  def display_seed_availability(member, crop)
    total_quantity = 0
    member.seeds.each do |seed|
      if seed.crop.name == crop.name
        total_quantity = total_quantity + seed.quantity
      end
    end

    if (total_quantity != 0)
      "You have #{pluralize(total_quantity, "seed")} of this crop."
    else
      "You don't have any seeds of this crop."
    end
  
  end
end