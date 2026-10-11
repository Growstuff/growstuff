# frozen_string_literal: true

module ActivitiesHelper
  def activities_kanban_props(activities)
    initial_activities = activities.map do |activity|
      {
        id: activity.id,
        slug: activity.slug,
        name: activity.name,
        category: activity.category,
        status: activity.status || (activity.finished? ? 'done' : 'planned'),
        due_date: activity.due_date&.strftime('%b %d, %Y'),
        garden_name: activity.garden&.name,
        planting_name: activity.planting&.crop&.name,
        description: activity.description,
        url: activity_path(activity)
      }
    end

    {
      initialActivities: initial_activities,
      newActivityUrl: new_activity_path
    }
  end
end
