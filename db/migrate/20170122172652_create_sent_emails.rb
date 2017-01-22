class CreateSentEmails < ActiveRecord::Migration
  def change
    create_table :sent_emails do |t|
        t.integer :user_id
        t.date :sent_date
        t.string :allowable_frequency
        t.string :source

      t.timestamps null: false
    end
    add_index :sent_emails, :user_id
  end
end
