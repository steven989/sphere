class AddConnectionToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :connection_id, :integer
  end
end
