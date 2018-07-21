class CreateFrames < ActiveRecord::Migration[5.2]
  def change
    create_table :frames do |t|
      t.references :player, foreign_key: true
      t.references :game, foreign_key: true
      t.integer :first_roll
      t.integer :second_roll
      t.integer :third_roll
      t.integer :score, default: 0
      t.boolean :strike
      t.boolean :spare
      t.boolean :final_frame
      t.integer :position

      t.timestamps
    end
  end
end
