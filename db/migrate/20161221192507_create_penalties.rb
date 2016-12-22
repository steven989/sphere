class CreatePenalties < ActiveRecord::Migration
  def change
    create_table :penalties do |t|
        t.integer :user_id
        t.integer :statistic_definition_id
        t.date :penalty_date
        t.string :penalty_statistic
        t.string :penalty_type
        t.float :amount

      t.timestamps null: false
    end
    add_index :penalties, :user_id
    add_index :penalties, :statistic_definition_id
  end
end
