namespace :openfarm do
  desc "Retrieve crop info from open farm"
  # usage: rake growstuff:admin_user name=skud

  task import: :environment do
    OpenfarmService.new.import!
  end
end
