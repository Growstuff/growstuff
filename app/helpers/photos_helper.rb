# frozen_string_literal: true

module PhotosHelper
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
      url:        post_path(post),
      subject:    post.subject,
      excerpt:    truncate(strip_tags(markdownify(post.body)), length: 90, separator: ' '),
      byline:     "by #{post.author} · #{l(post.created_at.to_date, format: :short)}",
      selectedId: post.card_photo_id,
      addPhotoUrl: new_photo_path_for(post),
      addPhotoLabel: photo_label(post),
      photos:     post.photos.map { |p| { id: p.id, title: p.title, thumbnail_url: p.thumbnail_url, fullsize_url: p.fullsize_url } }
    }
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
