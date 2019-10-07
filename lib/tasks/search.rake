namespace :search do
  desc 'reindex'
  task reindex: :environment do
    Crop.all.each_slice(50) { |batch| Crop.searchkick_index.import(batch) }
  end
end
