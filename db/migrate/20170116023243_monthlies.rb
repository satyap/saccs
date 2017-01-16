class Monthlies < ActiveRecord::Migration
  def change
    create_table :monthlies do |t|
      t.integer :account_id
      t.string :name
      t.decimal  "start_amount",      precision: 10, scale: 2
      t.decimal  "end_amount",      precision: 10, scale: 2
    end
  end
end
