class CreateProposalTokens < ActiveRecord::Migration
  def up
    create_table :proposal_tokens do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.string :proposable_type
      t.text :arguments

      t.datetime :accepted_at
      t.datetime :expires_at
      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :proposal_tokens, :token, unique: true
    add_index :proposal_tokens, :email
    add_index :proposal_tokens, :proposable_type
  end

  def down
    drop_table :proposal_tokens
  end
end
