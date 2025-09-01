class AddProblems < ActiveRecord::Migration[7.2]
  def change
    create_table :problems do |t|
      t.string :name
      t.string :reason_for_rejection
      t.string :rejection_notes
      t.string :approval_status, null: false, default: "pending"
      t.references :requester, foreign_key: { to_table: :members }
      t.references :creator, foreign_key: { to_table: :members }
      t.string :slug

      t.index :name
      t.index :slug
      t.timestamps
    end

    create_table :problem_posts do |t|
      t.references :problem, foreign_key: true
      t.references :post, foreign_key: true

      t.index %i(problem_id post_id), unique: true
      t.timestamps
    end

    create_table :planting_problems do |t|
      t.references :planting, foreign_key: true
      t.references :problem, foreign_key: true

      t.index %i(planting_id problem_id), unique: true
      t.timestamps
    end
  end
end
