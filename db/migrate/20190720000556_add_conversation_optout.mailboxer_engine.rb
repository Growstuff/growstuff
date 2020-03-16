# frozen_string_literal: true

# This migration comes from mailboxer_engine (originally 20131206080416)
class AddConversationOptout < ActiveRecord::Migration[4.2]
  def self.up
    create_table :mailboxer_conversation_opt_outs do |t|
      t.references :unsubscriber, polymorphic: true
      t.references :conversation
      t.timestamps null: false
    end
    add_foreign_key "mailboxer_conversation_opt_outs", "mailboxer_conversations",
                    name: "mb_opt_outs_on_conversations_id", column: "conversation_id"
  end

  def self.down
    remove_foreign_key "mailboxer_conversation_opt_outs", name: "mb_opt_outs_on_conversations_id"
    drop_table :mailboxer_conversation_opt_outs
  end
end
