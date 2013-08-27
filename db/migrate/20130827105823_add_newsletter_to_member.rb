class AddNewsletterToMember < ActiveRecord::Migration
  def change
    add_column :members, :newsletter, :boolean
  end
end
