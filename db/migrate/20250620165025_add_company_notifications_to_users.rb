class AddCompanyNotificationsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :company_notifications, :boolean
  end
end
