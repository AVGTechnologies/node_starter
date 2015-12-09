class CreateNodes < ActiveRecord::Migration
  def change
    create_table :nodes do |t|
      t.integer :build_id
      t.integer :pid
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :aborted_at
      t.string :status
      t.integer :abort_attempts
      t.boolean :killed

      t.timestamps null: false
    end
  end
end
