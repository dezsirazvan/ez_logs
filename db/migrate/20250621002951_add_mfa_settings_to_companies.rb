class AddMfaSettingsToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :mfa_required, :boolean, default: false, null: false
    add_column :companies, :mfa_grace_period_days, :integer, default: 30, null: false
  end
end
