class AddIndicatorForCalendarInclusion < ActiveRecord::Migration
  def change
    add_column :plans, :put_on_calendar, :boolean, default: false
  end
end
