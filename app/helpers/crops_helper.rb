# frozen_string_literal: true

module CropsHelper
  def crop_or_parent(crop, attribute)
    default = crop.send(attribute)
    return default if default.present?

    parent = crop
    while parent = parent.parent
      return parent.send(attribute) if parent&.send(attribute).present?
    end

    # For scopes, arrays, etc return the empty value
    default
  end

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

  def crop_jsonld_data(crop, full_attributes: true)
    same_as_urls = [crop.en_wikipedia_url]
    crop.scientific_names.each do |scientific_name|
      same_as_urls << "https://www.wikidata.org/wiki/#{scientific_name.wikidata_id}" if scientific_name.wikidata_id.present?
    end

    subject_of_entities = []
    if full_attributes
      if crop.en_youtube_url.present?
        subject_of_entities << {
          '@type': "VideoObject",
          url:     crop.en_youtube_url
        }
      end

      crop.posts.each do |post|
        subject_of_entities << {
          '@type': "SocialMediaPosting",
          url:     post_url(post),
          author:  {
            '@type': 'Person',
            name: post.author.login_name
          },
          datePublished: post.created_at
        }
      end

      images = []
      crop.photos.each do |photo|
        images << photo.fullsize_url
      end
    end

    # TODO: Review plantings, seeds, harvests as a subtype of social media post or event that ended? Or creative work?
    # has_many :plantings, dependent: :destroy
    # has_many :seeds, dependent: :destroy
    # has_many :harvests, dependent: :destroy

    {
      '@context':     "https://schema.org",
      '@type':        "BioChemEntity",
      name:           crop.name,
      taxonomicRange: crop.scientific_names.map(&:name),
      description:    crop.description,
      sameAs:         same_as_urls,
      alternateName:  crop.alternate_names.map(&:name),
      subjectOf:      subject_of_entities,
      image:          images
    }.compact
  end
end
