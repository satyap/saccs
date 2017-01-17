class RenameMonthliesToMonths < ActiveRecord::Migration
  def change
    rename_table :monthlies, :months
  end
end
