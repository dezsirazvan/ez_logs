class RemoveCompanyNotificationsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :company_notifications, :boolean
  end
end
