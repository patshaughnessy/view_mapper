class CreateChildModels < ActiveRecord::Migration
  def self.up
    create_table :child_models do |t|
      t.string :first_name
      t.string :last_name
      t.string :address
      t.boolean :some_flag
      t.integer :parent_model_id
      t.integer :second_parent_model_id

      t.timestamps
    end
  end

  def self.down
    drop_table :child_models
  end
end
