class CreateUserSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :ended_at
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end
  end
end
