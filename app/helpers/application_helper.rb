module ApplicationHelper
  def price_in_dollars(price)
    format('%.2f', price / 100.0)
  end

  # 999 cents becomes 9.99 AUD -- for products/orders/etc
  def price_with_currency(price)
    format('%.2f %s', price / 100.0, Growstuff::Application.config.currency)
  end

  def parse_date(str)
    str ||= '' # Date.parse barfs on nil
    str == '' ? nil : Date.parse(str)
  end

  def forex_link(price)
    pid = price_in_dollars(price)
    currency = Growstuff::Application.config.currency
    link = "http://www.wolframalpha.com/input/?i=#{pid}+#{currency}"

    link_to "(convert)", link, target: "_blank", rel: "noopener noreferrer"
  end

  def build_alert_classes(alert_type = :info)
    classes = 'alert alert-dismissable '
    case alert_type.to_sym
    when :alert, :danger, :error, :validation_errors
      classes += 'alert-danger'
    when :warning, :todo
      classes += 'alert-warning'
    when :notice, :success
      classes += 'alert-success'
    when :info
      classes += 'alert-info'
    end
    classes
  end

  # Produces a cache key for uniquely identifying cached fragments.
  def cache_key_for(klass, identifier = "all")
    count          = klass.count
    max_updated_at = klass.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "#{klass.name.downcase.pluralize}/#{identifier}-#{count}-#{max_updated_at}"
  end

  def required_field_help_text
    asterisk = content_tag :span, '*', class: ['red']
    text = content_tag :em, 'denotes a required field'
    content_tag :div, asterisk + ' '.html_safe + text, class: ['margin-bottom']
  end

  #
  # Returns an image uri for a given member.
  #
  # Falls back to Gravatar
  #
  def avatar_uri(member, size = 150)
    return unless member
    if member.preferred_avatar_uri.present?
      # Some avatars support different sizes
      # http://graph.facebook.com/12345678/picture?width=150&height=150
      uri = URI.parse(member.preferred_avatar_uri)

      if uri.host == 'graph.facebook.com'
        uri.query = "&width=#{size}&height=#{size}"
      end

      # TODO: Assess twitter - https://dev.twitter.com/overview/general/user-profile-images-and-banners
      # TODO: Assess flickr  - https://www.flickr.com/services/api/misc.buddyicons.html

      return uri.to_s
    end

    Gravatar.new(member.email).image_url(size: size,
                                         default: :identicon)
  end

  # Returns a string with the quantity and the right pluralization for a
  # given collection and model.
  def localize_plural(collection, model)
    size       = collection.size
    model_name = model.model_name.human(count: size)
    "#{size} #{model_name}"
  end

  def show_inactive_tickbox_path(type, owner, show_all)
    all = show_all ? '' : 1
    if owner
      plantings_by_owner_path(owner: owner.slug, all: all) if type == 'plantings'
      gardens_by_owner_path(owner: owner.slug, all: all) if type == 'gardens'
    else
      plantings_path(all: all) if type == 'plantings'
      gardens_path(all: all) if type == 'gardens'
    end
  end

  def title(type, owner, crop, planting)
    if owner
      t(".title.owner_#{type}", owner: owner.login_name)
    elsif crop
      t(".title.crop_#{type}", crop: crop.name)
    elsif planting
      t(".title.planting_#{type}", planting: planting.to_s)
    else
      t(".title.default")
    end
  end

  def og_description(description)
    strip_tags(description).split(' ')[0..20].join(' ')
  end
end
