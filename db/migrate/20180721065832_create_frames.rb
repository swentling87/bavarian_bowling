class CreateFrames < ActiveRecord::Migration[5.2]
  def change
    create_table :frames do |t|
      t.references :player, foreign_key: true
      t.references :game, foreign_key: true
      t.integer :first
      t.integer :second
      t.integer :third
      t.boolean :final_frame
      t.integer :position

      t.timestamps
    end
  end
end
