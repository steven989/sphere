class AddColumnToSystemSettingAndConnection < ActiveRecord::Migration
  def change
    add_column :system_settings, :description, :string
    add_column :connections, :target_contact_interval_in_days, :integer
  end
end
