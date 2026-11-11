# frozen_string_literal: true

# The job to plant a crop in a season, as the suggestions page adds it to a member's planned jobs: "Plant corn for spring
# 2026", linked to the crop and due when the season starts, or today when it is under way. The name says the season, so a crop
# can be planned for spring and again for summer, and a season is not added twice while its job isn't done. It holds the
# working out and no text, bar the name.
class SuggestedPlantJob
  # climate: the member's SeasonalClimate, which says when a season starts, or nil.
  def initialize(member, climate)
    @member = member
    @climate = climate
  end

  # The name of the job for the crop in the season, a season name such as 'spring'. Without a season, as for any plant job.
  def name(crop, season_name)
    season = season(season_name)
    return I18n.t('job_ideas.job.plant', crop: crop.name) unless season

    I18n.t('suggested_jobs.plant_for_season', crop: crop.name, season: I18n.t("seasons.#{season.name}").downcase,
                                              year: @climate.starts_on(season).year)
  end

  # Whether the member has that job already, and it isn't done.
  def planned?(crop, season_name)
    planned.include?([crop.id, name(crop, season_name)])
  end

  # Makes the job unless it is planned. Returns the job made, or nil.
  def add(crop, season_name)
    return if planned?(crop, season_name)

    season = season(season_name)
    @member.jobs.create!(name: name(crop, season_name), jobbable: crop, action: 'plant', due_date: (@climate.due_on(season) if season))
  end

  private

  def season(season_name)
    @climate&.seasons&.find { |candidate| candidate.name.to_s == season_name.to_s }
  end

  # [crop id, name] of each of the member's jobs to plant a crop that isn't done.
  def planned
    @planned ||= @member.jobs.active.where(action: 'plant', jobbable_type: 'Crop').pluck(:jobbable_id, :name)
  end
end
