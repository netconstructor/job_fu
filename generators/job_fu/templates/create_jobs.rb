class CreateJobs < ActiveRecord::Migration
  
  def self.up
    create_table :jobs do |t|
      t.column :priority,           :integer, :default => 0
      t.column :status,             :string,  :limit => 20
      t.column :worker,             :string
      t.column :status_description, :text
      t.column :processable,        :mediumtext
      t.column :process_at,         :datetime
      t.column :processed_at,       :datetime
    end

    add_index :jobs, [:status, :process_at, :worker, :priority, :id], :name => "next_in_queue"
  end
  
  def self.down
    remove_index :jobs, :name => "next_in_queue"
    drop_table :jobs
  end
  
end