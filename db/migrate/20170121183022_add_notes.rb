class AddNotes < ActiveRecord::Migration
  def change
    add_column :activities, :notes, :text
  end
end
