module CropsHelper
  def display_seed_availability(member, crop)
    total_quantity = 0

    seeds = member.seeds.select {|seed| seed.crop.name == crop.name }

    seeds.each do |seed|
      total_quantity = total_quantity + seed.quantity if seed.quantity
    end

    if !seeds.any?
      return "You don't have any seeds of this crop."
    end

    if (total_quantity != 0)
      "You have #{total_quantity} #{Seed.model_name.human(count: total_quantity)} of this crop."
    else
      "You have an unknown quantity of seeds of this crop."
    end
  end
end
