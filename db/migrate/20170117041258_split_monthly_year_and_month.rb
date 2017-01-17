class SplitMonthlyYearAndMonth < ActiveRecord::Migration
  def change
    add_column :months, :year, :integer, limit: 4
    add_column :months, :month, :integer, limit: 4
    remove_column :months, :name
  end
end
