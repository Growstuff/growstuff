
namespace :search do
  desc "Create elastic search index"
  task create: :environment do
    Crop.__elasticsearch__.create_index! force: true
  end

  desc 'Refresh elastic search index'
  task refresh: :environment do
  	Crop.__elasticsearch__.refresh_index!
  end
end
