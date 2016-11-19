class CreateBadges < ActiveRecord::Migration
  def change
    create_table :badges do |t|
        t.string :name
        t.string :description
        t.string :criteria

      t.timestamps null: false
    end
  end
end
