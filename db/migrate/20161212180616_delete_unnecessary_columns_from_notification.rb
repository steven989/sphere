class DeleteUnnecessaryColumnsFromNotification < ActiveRecord::Migration
  def change
    remove_column :notifications, :connection_id
    remove_column :notifications, :display_elements
  end
end
