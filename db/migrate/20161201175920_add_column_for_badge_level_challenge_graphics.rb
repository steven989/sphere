class AddColumnForBadgeLevelChallengeGraphics < ActiveRecord::Migration
  def change
    add_column :badges, :graphic, :string
    add_column :levels, :graphic, :string
    add_column :challenges, :graphic, :string
  end
end
