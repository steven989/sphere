class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
        t.string :name
        t.text :instructions
        t.text :description
        t.string :criteria
        t.string :reward

      t.timestamps null: false
    end
  end
end
