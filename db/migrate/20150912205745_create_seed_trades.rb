class CreateSeedTrades < ActiveRecord::Migration
  def change
    create_table :seed_trades do |t|
      t.text       :message
      t.text       :address
      t.datetime   :requested_date
      t.datetime   :accepted_date
      t.datetime   :declined_date
      t.datetime   :sent_date
      t.datetime   :received_date
      t.references :seed,                           index: true
      t.references :requester, references: :member, index: true

      t.timestamps
    end
  end
end
