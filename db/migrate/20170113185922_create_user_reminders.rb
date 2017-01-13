class CreateUserReminders < ActiveRecord::Migration
  def change
    create_table :user_reminders do |t|
        t.integer :user_id
        t.integer :connection_id
        t.string :reminder
        t.string :status
        t.date :due_date
      t.timestamps null: false
    end

    add_index :user_reminders, :user_id
    add_index :user_reminders, :connection_id
    
  end
end
