# frozen_string_literal: true

# What the front page's invitation to see the weather at your place says, from a WeatherInvitation. The working out is in
# WeatherInvitation, FrostSeason and PlaceClimate and the words are in the locale files; this puts the two together.
module WeatherInvitationHelper
  FROST_DATES = { before_season: :first, in_season: :last, passed: :next }.freeze

  # The sentence above the three cards.
  def weather_invitation_intro(invitation)
    t("home.weather_invitation.intro.#{invitation.state}", place: invitation.place_name)
  end

  # { measure:, label:, title:, note: } for frost, rain and temperature, in the invitation's state.
  def weather_invitation_cards(invitation)
    %i(frost rain air).map do |measure|
      words = case invitation.state
              when :ready then weather_invitation_headline(invitation, measure) || weather_invitation_words(measure, :loading)
              else weather_invitation_words(measure, invitation.state)
              end
      { measure:, label: t("home.weather_invitation.labels.#{measure}"), **words }
    end
  end

  def weather_invitation_icon(measure)
    measure == :frost ? frost_icon(:before_season) : climate_icon(measure)
  end

  private

  def weather_invitation_words(measure, state)
    { title: t("home.weather_invitation.#{state}.#{measure}.title"), note: t("home.weather_invitation.#{state}.#{measure}.note") }
  end

  # The headline for a measure, or nil when its weather isn't in yet.
  def weather_invitation_headline(invitation, measure)
    case measure
    when :frost then weather_invitation_frost(invitation.frost)
    when :rain then weather_invitation_rain(invitation.climate)
    else weather_invitation_air(invitation.climate)
    end
  end

  def weather_invitation_frost(frost)
    return unless frost

    verdict = frost.verdict
    note = if verdict == :rare then t('home.weather_invitation.ready.frost.rare')
           else weather_invitation_frost_note(frost, verdict)
           end
    { title: frost_verdict(frost)[:title], note: }
  end

  def weather_invitation_frost_note(frost, verdict)
    date = case FROST_DATES[verdict]
           when :first then frost.usual.first
           when :last then frost.usual.last
           when :next then frost.next_season_start
           else frost.possible.last
           end
    t("home.weather_invitation.ready.frost.#{verdict}", date: frost_date_text(date))
  end

  def weather_invitation_rain(climate)
    comparison = climate&.rain_comparison
    return unless comparison

    { title: t("home.weather_invitation.ready.rain.#{comparison}"),
      note: t('home.weather_invitation.ready.rain.note', percent: (climate.rain_share * 100).round) }
  end

  def weather_invitation_air(climate)
    comparison = climate&.air_comparison
    return unless comparison

    difference = climate.air_difference
    key = if comparison == :close then 'note_close'
          else difference.negative? ? 'note_below' : 'note_above'
          end
    { title: t("home.weather_invitation.ready.air.#{comparison}"),
      note: t("home.weather_invitation.ready.air.#{key}", difference: difference.abs) }
  end
end
