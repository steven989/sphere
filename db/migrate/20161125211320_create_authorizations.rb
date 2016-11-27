class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
        t.integer :user_id
        t.string  :provider
        t.text  :data

      t.timestamps null: false
    end
  end
end
