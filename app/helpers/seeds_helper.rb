module SeedsHelper
  def display_seed_description(seed)
    if seed.description.nil?
      "no description provided."
    else
      truncate(seed.description, length: 130, separator: ' ', omission: '... ') { link_to "Read more", seed_path(seed) }
    end
  end
end
