class AddMissingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :confirmed_at, :datetime
    add_column :users, :mfa_enabled, :boolean, default: false, null: false
    add_column :users, :two_factor_secret, :string
    add_column :users, :backup_codes, :json, default: []
    add_column :users, :email_notifications, :boolean, default: true, null: false
    add_column :users, :alert_notifications, :boolean, default: true, null: false
    add_column :users, :team_notifications, :boolean, default: true, null: false
    add_column :users, :timezone, :string, default: 'UTC', null: false
    add_column :users, :language, :string, default: 'en', null: false
    add_column :users, :login_count, :integer, default: 0
    add_column :users, :last_login_at, :datetime
    add_column :users, :failed_login_attempts, :integer, default: 0
    add_column :users, :locked_at, :datetime
    
    add_index :users, :email, unique: true
    add_index :users, :confirmed_at
    add_index :users, :locked_at
  end
end
