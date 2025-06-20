class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.string :action
      t.string :resource_type
      t.bigint :resource_id
      t.string :ip_address
      t.string :user_agent
      t.json :metadata

      t.timestamps
    end
  end
end
