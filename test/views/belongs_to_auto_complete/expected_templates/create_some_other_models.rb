class CreateSomeOtherModels < ActiveRecord::Migration
  def self.up
    create_table :some_other_models do |t|
      t.string :first_name
      t.string :last_name
      t.string :address
      t.boolean :some_flag
      t.integer :parent_id
      t.integer :second_parent_id

      t.timestamps
    end
  end

  def self.down
    drop_table :some_other_models
  end
end
