class CreateTestModel < ActiveRecord::Migration
  def self.up
    create_table :test_models do |t|
      t.string :name
      t.integer :amount
      t.datetime :last_updated
      t.string :bee_larvae_type
    end
  end

  def self.down
    drop_table :test_models
  end
end
