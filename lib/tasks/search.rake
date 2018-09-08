
namespace :search do
  desc "Create elastic search index"
  task create: :environment do
    Crop.__elasticsearch__.create_index! force: true
  end
end
