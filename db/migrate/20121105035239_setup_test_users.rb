class SetupTestUsers < ActiveRecord::Migration
  def up
    if Rails.env.development? or Rails.env.test?
      (1..3).each do |i|
        @user = User.create(:username => "test#{i}", :email => "test#{i}@example.com", :password => "password#{i}")
        @user.save!
      end
    end
  end

  def down
    if Rails.env.development? or Rails.env.test?
      (1..3).each do |i|
        @user = User.find_by_username("test#{i}")
        @user.try(:destroy)
      end
    end
  end
end
