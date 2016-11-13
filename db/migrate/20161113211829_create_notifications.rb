class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
        t.integer :user_id
        t.string :notification_type
        t.date :notification_date
        t.date :expiry_date
        t.string :data_type
        t.string :value

      t.timestamps null: false
    end
  end
end
