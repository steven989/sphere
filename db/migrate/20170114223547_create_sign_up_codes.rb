class CreateSignUpCodes < ActiveRecord::Migration
  def change
    create_table :sign_up_codes do |t|
        t.integer :user_id
        t.string :code
        t.integer :quantity
        t.integer :quantity_used
        t.string :description
        t.date :valid_after
        t.date :valid_before
        t.string :code_type
        t.boolean :active

      t.timestamps null: false
    end
    add_index :sign_up_codes, :user_id
    add_index :sign_up_codes, :code, unique:true
  end
end
