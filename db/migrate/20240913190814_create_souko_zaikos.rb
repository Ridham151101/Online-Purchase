class CreateSoukoZaikos < ActiveRecord::Migration[7.0]
  def change
    create_table :souko_zaikos do |t|
      t.string :warehouse_code
      t.string :sku_code
      t.string :stock_type
      t.integer :stock

      t.timestamps
    end
  end
end
