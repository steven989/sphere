class AddLengthAndEditTimeLinkToPlanModel < ActiveRecord::Migration
  def change
    add_column :plans, :length, :float
    add_column :plans, :edit_time_url, :string
    add_column :plans, :details, :text
  end
end
