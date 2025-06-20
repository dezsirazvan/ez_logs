class CreateUserSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :session_token
      t.datetime :expires_at
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_activity_at

      t.timestamps
    end
  end
end
