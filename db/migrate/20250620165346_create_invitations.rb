class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :company, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :status, null: false, default: 'pending'
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.text :message
      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, :status
    add_index :invitations, :expires_at
  end
end
