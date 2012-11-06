class CreateProposalTokens < ActiveRecord::Migration
  def up
    create_table :proposal_tokens do |t|
      t.string  :token,           null: false
      t.string  :email,           null: false
      t.string  :proposable_type, null: false
      t.string  :resource_type
      t.integer :resource_id
      t.text    :arguments

      t.datetime :accepted_at
      t.datetime :reminded_at
      t.datetime :expires_at,     null: false
      t.datetime :updated_at,     null: false
      t.datetime :created_at,     null: false
    end

    add_index :proposal_tokens, :token, unique: true

    execute <<-SQL
CREATE UNIQUE INDEX proposal_idx ON proposal_tokens (
  email,
  proposable_type,
  resource_type,
  resource_id,
  expires_at,
  accepted_at
)
    SQL
  end

  def down
    drop_table :proposal_tokens
  end
end
