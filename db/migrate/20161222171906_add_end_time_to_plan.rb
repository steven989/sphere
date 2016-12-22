class AddEndTimeToPlan < ActiveRecord::Migration
  def change
    add_column :plans, :end_date_time, :datetime
  end
end
