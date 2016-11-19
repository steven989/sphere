class CreateStatisticDefinitions < ActiveRecord::Migration
  def change
    create_table :statistic_definitions do |t|
        t.string :name
        t.string :description
        t.string :definition

      t.timestamps null: false
    end
  end
end
