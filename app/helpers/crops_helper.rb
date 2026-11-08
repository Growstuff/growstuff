# frozen_string_literal: true

module CropsHelper
  # "5–10 days", or "7 days": a range of days given as medians, so rounded; nil when there is none.
  def growing_days(min, max)
    text = days_range_text(min&.round, max&.round)
    "#{text} days" if text
  end

  # The facts about growing a crop that come as a figure: what a crop wrangler set, and
  # the median of members' seed packets.
  def growing_facts(crop)
    [
      { title: 'Row Spacing', set: growing_cm(crop.row_spacing.presence), median: growing_cm(crop.median_row_spacing) },
      { title:  'Germination',
        set:    growing_days(crop.germination_days_min, crop.germination_days_max),
        median: growing_days(crop.median_germination_days_min, crop.median_germination_days_max) },
      { title:  'Days until maturity',
        set:    growing_days(crop.days_until_maturity_min, crop.days_until_maturity_max),
        median: growing_days(crop.median_days_until_maturity_min, crop.median_days_until_maturity_max) }
    ]
  end

  # How big the plant gets, as one fact: "10cm × 5cm" under "Height × spread", or just the one
  # of them when only one is known; nil when neither is.
  def size_fact(crop)
    sizes = { 'Height' => crop.height, 'Spread' => crop.spread }.compact_blank
    return if sizes.empty?

    { title: sizes.size == 2 ? 'Height × spread' : sizes.keys.first, value: sizes.values.map { |value| "#{value}cm" }.join(' × ') }
  end

  # "45cm" or "37.5cm"; nil when there is none.
  def growing_cm(value)
    "#{number_with_precision(value, precision: 1, strip_insignificant_zeros: true)}cm" if value.present?
  end

  def crop_or_parent(crop, attribute)
    @crop_or_parent_cache ||= {}
    cache_key = [crop.persisted? ? crop.id : crop.object_id, attribute]
    return @crop_or_parent_cache[cache_key] if @crop_or_parent_cache.key?(cache_key)

    @crop_or_parent_cache[cache_key] = begin
      value = crop.send(attribute)
      if value.blank?
        parent = crop
        while (parent = parent.parent)
          parent_value = parent.send(attribute)
          if parent_value.present?
            value = parent_value
            break
          end
        end
      end
      value
    end
  end

  def display_seed_availability(member, crop)
    @seed_availability_cache ||= {}
    cache_key = [
      member.persisted? ? member.id : member.object_id,
      crop.persisted? ? crop.id : crop.object_id
    ]
    return @seed_availability_cache[cache_key] if @seed_availability_cache.key?(cache_key)

    @seed_availability_cache[cache_key] = begin
      seeds = member.seeds.active.where(crop:)

      if seeds.none?
        "You don't have any seeds of this crop."
      else
        total_quantity = seeds.where.not(quantity: nil).sum(:quantity)
        if total_quantity == 0
          "You have an unknown quantity of seeds of this crop."
        else
          "You have #{total_quantity} #{Seed.model_name.human(count: total_quantity)} of this crop."
        end
      end
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
    Rails.cache.fetch([crop.cache_key_with_version, "jsonld", full_attributes]) do
      same_as_urls = [crop.en_wikipedia_url]
      crop.scientific_names.each do |scientific_name|
        if scientific_name.wikidata_id.present?
          same_as_urls << "https://www.wikidata.org/wiki/#{scientific_name.wikidata_id}"
        end
      end

      subject_of_entities = []
      images = []
      if full_attributes
        if crop.en_youtube_url.present?
          subject_of_entities << {
            '@type': "VideoObject",
            url:     crop.en_youtube_url
          }
        end

        crop.posts.limit(50).each do |post|
          subject_of_entities << {
            '@type': "SocialMediaPosting",
            url:     post_url(post),
            author:  {
              '@type': 'Person',
              name:    post.author.login_name
            },
            datePublished: post.created_at
          }
        end

        crop.photos.limit(50).each do |photo|
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
end
