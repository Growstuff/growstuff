# frozen_string_literal: true

# The members a gardener can pick as having been given a seedling: the people they follow and the ones nearest them to begin
# with, and anyone on Growstuff by name when they search. Each person is described for the picker.
class StallRecipients
  # Only a few are shown, so the rest of the form stays in view.
  SHOWN = 3
  # How many of each kind to look at before choosing the nearest.
  POOL = 8

  def initialize(member)
    @member = member
  end

  # Neighbours and people they follow, the nearest first.
  def suggestions
    (followed + nearest).uniq.sort_by { |person| distance_km(person) || Float::INFINITY }.first(SHOWN).map { |person| describe(person) }
  end

  def search(query)
    term = Member.sanitize_sql_like(query.to_s.strip)
    return [] if term.length < 2

    pickable.where('members.login_name ILIKE ?', "%#{term}%").order(:login_name).limit(SHOWN).map { |person| describe(person) }
  end

  # One pickable person, described for the picker, or nil.
  def person(id)
    found = pickable.find_by(id:)
    describe(found) if found
  end

  # Someone who can be given a seedling, and who can be asked: the signed-in member with a confirmed address, not themself.
  def pickable
    Member.kept.confirmed.where.not(id: @member.id)
  end

  private

  def followed
    pickable.where(id: @member.follows.select(:followed_id)).order(:login_name).limit(POOL)
  end

  def nearest
    return Member.none unless @member.located?

    pickable.located.near([@member.latitude, @member.longitude], 1000).limit(POOL)
  end

  def describe(person)
    { id: person.id, name: person.to_s, place: place_of(person) }
  end

  def distance_km(person)
    return unless @member.located? && person.latitude.present? && person.longitude.present?

    Geocoder::Calculations.distance_between([@member.latitude, @member.longitude], [person.latitude, person.longitude], units: :km)
  end

  # "Miramar, 400 m away", or just where they are, or nothing.
  def place_of(person)
    return if person.location.blank?

    km = distance_km(person)
    return person.location unless km

    far = km < 1 ? I18n.t('stalls.recipients.metres', count: (km * 1000).round(-1)) : I18n.t('stalls.recipients.km', count: km.round(1))
    I18n.t('stalls.recipients.place', place: person.location, distance: far)
  end
end
