class AddMastodonClients < ActiveRecord::Migration[8.1]
  def change
    create_table "mastodon_clients" do |t|
      t.string :domain, null: false
      t.string :client_id, null: false
      t.text :client_secret, null: false, comment: 'Encrypted.'
      t.string :redirect_uri, null: false, comment: 'The callback URL the client was registered with; a server rejects any other.'

      t.timestamps
      t.index :domain, unique: true
    end
  end
end
