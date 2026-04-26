# frozen_string_literal: true

namespace :members do
  desc "Remove inactive members with no activity and last login > 24 months ago"
  # usage: rake members:cleanup_inactive
  # usage: DRY_RUN=true rake members:cleanup_inactive
  task cleanup_inactive: :environment do
    limit_date = 24.months.ago
    dry_run = ENV.fetch('DRY_RUN', 'false') == 'true'

    inactive_members = Member.where("last_sign_in_at < ? OR (last_sign_in_at IS NULL AND created_at < ?)", limit_date, limit_date)

    count = 0
    inactive_members.find_each do |member|
      # Check for activity using the model method
      unless member.has_activity?
        if dry_run
          puts "[DRY RUN] Would delete inactive member: #{member.login_name} (ID: #{member.id}, Last login: #{member.last_sign_in_at || 'Never'}, Created: #{member.created_at})"
        else
          puts "Deleting inactive member: #{member.login_name} (ID: #{member.id}, Last login: #{member.last_sign_in_at || 'Never'}, Created: #{member.created_at})"
          member.destroy
        end
        count += 1
      end
    end

    if dry_run
      puts "Total inactive members that would be deleted: #{count}"
    else
      puts "Total inactive members deleted: #{count}"
    end
  end
end
