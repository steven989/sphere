class AddFrequencyWordToConnection < ActiveRecord::Migration
  def change
    add_column :connections, :frequency_word, :string
    add_column :connections, :notes, :text
  end
end
