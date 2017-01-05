class AddOneTimeShowFlagToNotification < ActiveRecord::Migration
  def change
    add_column :notifications, :one_time_display, :boolean, default: false
  end
end
