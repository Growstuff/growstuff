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

  def youtube_video_id(url)
    return unless url

    regex = %r{(?:youtube(?:-nocookie)?\.com/(?:[^/\n\s]+/\S+/|(?:v|e(?:mbed)?)/|\S*?[?&]v=)|youtu\.be/)([a-zA-Z0-9_-]{11})}
    match = url.match(regex)
    match[1] if match
  end
end
