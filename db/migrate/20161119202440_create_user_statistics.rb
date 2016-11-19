class CreateUserStatistics < ActiveRecord::Migration
  def change
    create_table :user_statistics do |t|
        t.integer :user_id
        t.integer :statistic_definition_id
        t.string :name
        t.float :value

      t.timestamps null: false
    end
  end
end
