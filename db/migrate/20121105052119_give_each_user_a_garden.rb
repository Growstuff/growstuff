class GiveEachUserAGarden < ActiveRecord::Migration
  def up
    User.all.each do |user|
      garden = Garden.create(:name => "Garden", :user_id => user.id)
      garden.save!
    end
  end

  def down
    User.all.each do |user|
      garden = Garden.find_by_name_and_user_id("Garden", user.id)
      garden.try(:destroy)
    end
  end
end
