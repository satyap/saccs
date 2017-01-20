class AddTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.integer :account_id
      t.string :description
      t.decimal :amount,
        precision: 10, # total digits
        scale: 2 # digits after decimal point
      t.integer :date_year
      t.integer :date_month
      t.integer :date_day
      t.boolean :cleared, default: false
      t.timestamps
    end
  end
end
