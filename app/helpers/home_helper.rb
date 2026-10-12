# frozen_string_literal: true

module HomeHelper
  # What the home page's invitation to the garden layout tool says, and where
  # it goes. A member is sent straight to the layout of one of their gardens;
  # without an active garden there's nothing to lay out, so they're asked to
  # add one first; anyone signed out is asked to sign up.
  def garden_layout_invitation(garden)
    if garden.present?
      { href:    layout_member_garden_path(garden.owner, garden),
        heading: "Map out #{garden.name}",
        pitch:   'Drag your plants onto a picture of the bed, and see what fits where.',
        cta:     'Try out the new garden layout tool →' }
    elsif member_signed_in?
      { href:    new_garden_path,
        heading: 'Map out your garden beds',
        pitch:   'Add a garden, then drag the plants in it onto a picture of the bed.',
        cta:     'Add a garden →' }
    else
      { href:    new_member_registration_path,
        heading: 'Map out your garden beds',
        pitch:   "Lay out what you're growing on a picture of each bed, plant by plant.",
        cta:     'Sign up to try it →' }
    end
  end

  # How long ago something happened, in words. Dates have no time of day, and
  # time_ago_in_words reads one as midnight, so something done today would be
  # "19 hours ago"; a date is described by the day instead.
  def ago_in_words(value)
    return t('home.dashboard.relative.ago', time: time_ago_in_words(value)) if value.respond_to?(:hour)

    days = (Time.zone.today - value.to_date).to_i
    case days
    when ..0 then t('home.dashboard.relative.today')
    when 1 then t('home.dashboard.relative.yesterday')
    else t('home.dashboard.relative.ago', time: distance_of_time_in_words(value.to_date, Time.zone.today))
    end
  end
end
