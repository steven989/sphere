class AddTesterIndicatorToUser < ActiveRecord::Migration
  def change
    add_column :users, :tester, :boolean
  end
end
