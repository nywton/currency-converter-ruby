class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :from_currency
      t.string :to_currency
      t.decimal :from_value, precision: 18, scale: 2, null: false
      t.decimal :to_value,   precision: 18, scale: 2, null: false
      t.decimal :rate,       precision: 18, scale: 4, null: false

      t.timestamps
    end
  end
end
