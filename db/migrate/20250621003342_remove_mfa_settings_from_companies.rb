class RemoveMfaSettingsFromCompanies < ActiveRecord::Migration[8.0]
  def change
    remove_column :companies, :mfa_required, :boolean
    remove_column :companies, :mfa_grace_period_days, :integer
  end
end
