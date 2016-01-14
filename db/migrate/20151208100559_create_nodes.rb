class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.integer :build_id
      t.integer :pid,              default: -1
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :aborted_at
      t.string :status
      t.string :path
      t.string :uri

      t.timestamps null: false
    end
  end
end
