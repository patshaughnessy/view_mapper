class CreateTestModels < ActiveRecord::Migration
  def self.up
    create_table :test_models do |t|
      t.string :first_name
      t.string :last_name
      t.string :address
      t.boolean :some_flag
      t.string   :avatar_file_name
      t.string   :avatar_content_type
      t.integer  :avatar_file_size
      t.datetime :avatar_updated_at
      t.string   :avatar2_file_name
      t.string   :avatar2_content_type
      t.integer  :avatar2_file_size
      t.datetime :avatar2_updated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :test_models
  end
end
