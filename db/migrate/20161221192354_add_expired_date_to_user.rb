class AddExpiredDateToUser < ActiveRecord::Migration
  def change
    add_column :connections, :date_inactive, :date
  end
end
