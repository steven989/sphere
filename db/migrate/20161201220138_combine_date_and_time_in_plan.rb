class CombineDateAndTimeInPlan < ActiveRecord::Migration
  def change
    remove_column :plans, :time
    add_column :plans, :date_time, :datetime
  end
end
