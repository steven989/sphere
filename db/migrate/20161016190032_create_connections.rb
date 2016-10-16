class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
        t.integer :user_id
        t.string :first_name
        t.string :last_name
        
      t.timestamps null: false
    end
  end
end
