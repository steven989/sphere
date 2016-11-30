class CreateUserSettings < ActiveRecord::Migration
  def change
    create_table :user_settings do |t|
        t.integer :user_id
        t.string :value, default: '{}'

      t.timestamps null: false
    end
  end
end
