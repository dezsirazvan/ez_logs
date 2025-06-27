class AddNewFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :timing, :json
    add_column :events, :environment, :json
    add_column :events, :impact, :json
  end
end
