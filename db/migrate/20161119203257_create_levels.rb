class CreateLevels < ActiveRecord::Migration
  def change
    create_table :levels do |t|
        t.integer :user_id
        t.integer :level
        t.string :criteria

      t.timestamps null: false
    end
  end
end
