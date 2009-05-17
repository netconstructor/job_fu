class CreateJobs < ActiveRecord::Migration
  
  def self.up
    create_table :jobs do |t|
      t.column :priority,           :integer, :default => 0
      t.column :status,             :string,  :limit => 20
      t.column :status_description, :text
      t.column :processable,        :text
      t.column :processed_at,       :datetime
    end    
  end
  
  def self.down
    drop_table :jobs
  end
  
end
