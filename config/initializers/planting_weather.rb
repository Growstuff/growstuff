# frozen_string_literal: true

# Cover password and OAuth sign-ins, but not loading an existing session on each request.
Warden::Manager.after_set_user except: :fetch do |member, _warden, options|
  BackfillMemberWeatherJob.perform_later(member.id) if options[:scope] == :member && Feature.enabled?(:planting_weather)
end
