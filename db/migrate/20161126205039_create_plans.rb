class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
        t.integer :user_id
        t.integer :connection_id
        t.date :date
        t.time :time
        t.string :timezone
        t.string :name
        t.string :location
        t.string :status
        t.string :calendar_id
        t.string :calendar_event_id
        t.boolean :invite_sent

      t.timestamps null: false
    end
  end
end
