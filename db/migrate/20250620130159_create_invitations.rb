class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :email
      t.references :team, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :status
      t.datetime :expires_at
      t.string :token

      t.timestamps
    end
  end
end
