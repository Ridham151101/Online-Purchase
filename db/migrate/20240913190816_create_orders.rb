class CreateOrders < ActiveRecord::Migration[7.0]
  def change
    create_table :orders do |t|
      t.string :order_number
      t.integer :total_amount
      t.string :delivery_zipcode
      t.string :delivery_state
      t.string :delivery_city
      t.string :delivery_area
      t.string :delivery_address
      t.integer :tax

      t.timestamps
    end
  end
end
