namespace :search do
  desc 'reindex'
  task reindex: :environment do
    puts Crop.reindex
  end
end
