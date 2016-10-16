class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
        t.integer :user_id, null: false
        t.integer :connection_id
      t.timestamps null: false
    end
  end
end
