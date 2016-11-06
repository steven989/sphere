class ChangeInitiatorFieldType < ActiveRecord::Migration
  def change
    remove_column :activities, :initiator
    add_column :activities, :initiator, :integer
  end
end
