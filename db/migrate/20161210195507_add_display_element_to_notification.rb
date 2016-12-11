class AddDisplayElementToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :display_elements, :string, default: "[]"
  end
end
