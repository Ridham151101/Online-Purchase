class CreatePrefectureCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :prefecture_codes do |t|
      t.string :name
      t.string :code
      t.string :ew_flag

      t.timestamps
    end
  end
end
