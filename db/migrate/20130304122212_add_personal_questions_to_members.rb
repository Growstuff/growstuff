class AddPersonalQuestionsToMembers < ActiveRecord::Migration
  def change
    add_column :members, :gardening_since, :string
    add_column :members, :wish_i_could_grow, :string
    add_column :members, :gardening_clothes, :string
  end
end
