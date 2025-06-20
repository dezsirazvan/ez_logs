class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_reference :users, :role, null: false, foreign_key: true
    add_reference :users, :team, null: false, foreign_key: true
    add_column :users, :avatar, :string
    add_column :users, :two_factor_secret, :string
    add_column :users, :two_factor_backup_codes, :text
    add_column :users, :mfa_enabled, :boolean
    add_column :users, :last_login_at, :datetime
    add_column :users, :login_count, :integer
    add_column :users, :failed_login_attempts, :integer
    add_column :users, :locked_at, :datetime
  end
end
