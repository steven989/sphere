class AddMoreAttributesToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :initiator, :string
    add_column :activities, :activity, :string
    add_column :activities, :date, :date
    add_column :activities, :activity_description, :text
    add_column :activities, :activity_definition_id, :integer

  end
end
