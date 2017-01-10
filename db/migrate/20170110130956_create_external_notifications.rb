class CreateExternalNotifications < ActiveRecord::Migration
  def change
    create_table :external_notifications do |t|
      t.integer :user_id
      t.string :notification_type
      t.string :notification_medium
      t.timestamps null: false
    end
  end
end
