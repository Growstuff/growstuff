class AddMastodonClients < ActiveRecord::Migration[8.1]
  def change
    create_table "mastodon_clients" do |t|
      t.string :domain
      t.string :client_id
      t.text :client_secret
      t.index :domain, unique: true
    end
  end
end
