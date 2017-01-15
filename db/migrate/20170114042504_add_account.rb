class AddAccount < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string :name
      t.boolean :archived, default: false
    end
  end
end
