namespace :growstuff do

  desc "Add an admin user to Growstuff, by name"
  # usage: rake growstuff:admin_user name=skud

  task :admin_user => :environment do

    member = Member.find(ENV['name']) or raise "Usage: rake growstuff:admin_user name=whoever"
    admin  = Role.find_or_create_by_name!('admin')
    member.roles << admin

  end

end
