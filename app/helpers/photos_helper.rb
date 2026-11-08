# frozen_string_literal: true

module PhotosHelper
  RECORD_KINDS = %w(planting harvest seed garden post job).freeze

  # The records a photo card says more about, and the button that goes with each.
  DETAILED_RECORD_BUTTONS = {
    'planting' => 'btn-primary', 'harvest' => 'shows-card-button-harvest', 'seed' => 'btn-info'
  }.freeze

  # Everything the photo is attached to, as [type, record] pairs: the type is what
  # the photo associations route calls it ('planting', 'seed', 'crop').
  def photo_records(photo)
    RECORD_KINDS.flat_map { |type| photo.public_send(type.pluralize).map { |thing| [type, thing] } } +
      photo.crops.map { |crop| ['crop', crop] }
  end

  # The page's heading: "Photo of dill seeds". It says what the photo shows, from the
  # first thing it is attached to, as the site names things: "<crop> seeds", "<crop>
  # harvest", "<crop> planting". A photo of nothing we can name keeps its own title.
  def photo_heading(photo)
    subject = photo_subject(photo)
    subject ? t('photos.show.heading', subject: subject) : photo.title
  end

  def photo_subject(photo)
    photo_records(photo).each do |type, thing|
      case type
      when 'planting', 'harvest', 'seed' then return t("photos.records.#{type}", crop: thing.crop.name)
      when 'crop' then return photo_crop_subject(photo, thing)
      end
    end
    nil
  end

  # A photo added to a crop says whether it shows a planting, a harvest or seeds.
  def photo_crop_subject(photo, crop)
    kind = photo.photo_associations.find_by(photographable: crop)&.label
    kind ? t("photos.records.#{kind}", crop: crop.name) : crop.name
  end

  # Who a record belongs to: a post has an author, the rest an owner.
  def photo_record_owner(type, thing)
    type == 'post' ? thing.author : thing.owner
  end

  # The facts a record's card lists under its name: when, and how much.
  def photo_record_facts(type, thing)
    case type
    when 'planting'
      [(t('photos.shows.planting.planted', date: l(thing.planted_at)) if thing.planted_at),
       (t('photos.shows.planting.plants', count: thing.quantity) if thing.quantity)]
    when 'harvest'
      [(t('photos.shows.harvest.picked', date: l(thing.harvested_at)) if thing.harvested_at), thing.plant_part_name]
    when 'seed'
      [(t('photos.shows.seed.saved', date: l(thing.saved_at)) if thing.saved_at),
       (t('photos.shows.seed.seeds', count: thing.quantity) if thing.quantity)]
    else []
    end.compact_blank
  end

  # The site a photo is from, to name it: Flickr.
  def photo_source_name(photo)
    photo.source.to_s.titleize
  end

  # What to call a record in a list of them, so one planting is told from another.
  def photo_record_name(type, thing)
    case type
    when 'planting' then thing.display_name
    when 'harvest' then t('photos.records.harvest', crop: thing.crop.name)
    when 'seed' then t('photos.records.seed', crop: thing.crop.name)
    when 'post' then thing.subject
    else thing.to_s
    end
  end

  # Creative Commons licence addresses: .../licenses/by-nc/2.0/ or .../publicdomain/zero/1.0/
  LICENCE_URL = %r{creativecommons\.org/(?<family>licenses|publicdomain)/(?<type>[a-z-]+)(?:/(?<version>[\d.]+))?}
  LICENCE_TYPES = %w(by by-sa by-nc by-nc-sa by-nd by-nc-nd).freeze

  # Who to credit: the photographer where the photo came from someone who is not
  # the member that added it, otherwise the member.
  def photo_credit_name(photo)
    photo.author_name.presence || photo.owner.login_name
  end

  # The photographer is not a Growstuff member, so there is no profile to show.
  def photo_by_outsider?(photo)
    photo.author_name.present?
  end

  # What the licence allows, as the key of its summary: by, by-sa, ... zero, mark;
  # other for a licence we do not know, reserved for no licence address at all.
  def photo_licence_kind(photo)
    match = LICENCE_URL.match(photo.license_url.to_s)
    return photo.license_url.blank? ? 'reserved' : 'other' unless match

    if match[:family] == 'licenses'
      LICENCE_TYPES.include?(match[:type]) ? match[:type] : 'other'
    else
      { 'zero' => 'zero', 'mark' => 'mark' }.fetch(match[:type], 'other')
    end
  end

  # The short name of a Creative Commons licence, CC BY 2.0; nil for any other.
  def photo_licence_code(photo)
    match = LICENCE_URL.match(photo.license_url.to_s)
    return unless match

    case photo_licence_kind(photo)
    when *LICENCE_TYPES then "CC #{match[:type].upcase} #{match[:version]}".strip
    when 'zero' then "CC0 #{match[:version]}".strip
    when 'mark' then t('photos.licence.public_domain')
    end
  end

  # Who took it and where, as the start of a credit: "Photo by shiny on Flickr".
  def photo_credit_line(photo)
    line = t('photos.credit.by', name: photo_credit_name(photo))
    photo.source.present? ? line + t('photos.credit.on', site: photo.source.titleize) : line
  end

  # The credit to give, as plain text to copy: who took it, where, and the licence.
  def photo_credit_text(photo)
    credit = [photo_credit_line(photo), photo_licence_code(photo) || photo.license_name].join(', ')
    [credit, photo.license_url.presence].compact.join(' ')
  end

  # The name an add-photo link gives the dialog.
  def photo_label(model)
    case model
    when Seed then "#{model.crop.name} seeds"
    when Harvest then "#{model.crop.name} harvest"
    when Garden then "#{model.name} garden"
    when Planting then model.display_name
    when Post then model.subject
    when Job then model.name
    end
  end

  # The data attributes that make an add-photo link open the dialog.
  def photo_dialog_data(model)
    { photo_dialog: true, photo_label: photo_label(model) }
  end

  # The link that sets which side of a seed's packet a photo of it is of; an
  # empty label says it is not of the packet.
  def packet_label_path(seed, photo, label)
    photo_association_path(photo_id: photo.id, type: 'seed', id: seed.id, label:)
  end

  # The big copy of a photo, to read small print on: Flickr's 1024px size where the
  # photo is Flickr's, as `_z` is only 640px. Anything else has just the one size.
  def photo_large_url(photo)
    photo.source == 'flickr' ? photo.fullsize_url.sub(/_z(\.\w+)\z/, '_b\1') : photo.fullsize_url
  end

  def crop_image_path(crop)
    thumbnail_url(crop.default_photo)
  end

  def thumbnail_url(photo)
    if photo.nil?
      placeholder_image
    elsif photo.source == 'flickr'
      photo.fullsize_url
    else
      photo.thumbnail_url
    end
  end

  def garden_image_path(garden)
    photo_or_placeholder(garden)
  end

  def planting_image_path(planting)
    photo_or_placeholder(planting)
  end

  def harvest_image_path(harvest)
    photo_or_placeholder(harvest)
  end

  def seed_image_path(seed)
    photo_or_placeholder(seed)
  end

  def post_image_path(post)
    post.default_photo&.fullsize_url || post.crops.first&.default_photo&.fullsize_url || placeholder_image
  end

  # The same picture as post_image_path, at thumbnail size.
  def post_thumbnail_path(post)
    post.default_photo&.thumbnail_url || post.crops.first&.default_photo&.thumbnail_url || placeholder_image
  end

  # What the CardPhotoDialog island needs: where to save the choice, the post's
  # photos, and enough of the post to draw how its card will look.
  def card_photo_dialog_props(post)
    {
      url:           post_path(post),
      subject:       post.subject,
      excerpt:       truncate(strip_tags(markdownify(post.body)), length: 90, separator: ' '),
      byline:        "by #{post.author} · #{l(post.created_at.to_date, format: :short)}",
      selectedId:    post.card_photo_id,
      addPhotoUrl:   new_photo_path_for(post),
      addPhotoLabel: photo_label(post),
      photos:        post.photos.map { |p| { id: p.id, title: p.title, thumbnail_url: p.thumbnail_url, fullsize_url: p.fullsize_url } }
    }
  end

  # A post's photos, as the editor's islands draw them.
  def post_photo_props(post)
    post.photos.map { |p| { id: p.id, title: p.title, thumbnail_url: p.thumbnail_url, fullsize_url: p.fullsize_url } }
  end

  private

  def photo_or_placeholder(item)
    if item.default_photo.present?
      item_photo(item)
    elsif item.respond_to?(:crop)
      crop_image_path(item.crop)
    else
      placeholder_image
    end
  end

  def item_photo(item)
    item.default_photo.fullsize_url
  end

  def placeholder_image
    'placeholder_600.png'
  end
end
