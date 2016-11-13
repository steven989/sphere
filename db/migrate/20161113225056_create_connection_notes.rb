class CreateConnectionNotes < ActiveRecord::Migration
  def change
    create_table :connection_notes do |t|
        t.integer :user_id
        t.integer :connection_id
        t.text :notes

      t.timestamps null: false
    end
  end
end
