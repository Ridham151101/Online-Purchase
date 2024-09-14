class CreateOrderItems < ActiveRecord::Migration[7.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.string :sku_code
      t.integer :quantity
      t.integer :price
      t.integer :total_amount

      t.timestamps
    end
  end
end
