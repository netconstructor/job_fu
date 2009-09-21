ENV["RAILS_ENV"] = "test"
require 'rubygems'
require 'pathname'
require 'activerecord'
require 'spec/autorun'
require 'shoulda/rspec'
require 'factory_girl'
require File.dirname(__FILE__) + '/custom_matchers'

spec_dir = Pathname.new(__FILE__).dirname
$LOAD_PATH.unshift spec_dir.join('..', 'lib').expand_path
RAILS_ROOT = spec_dir.join('..').expand_path.to_s unless defined?(RAILS_ROOT)

require 'job_fu'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
ActiveRecord::Migration.verbose = false

ActiveRecord::Migration.suppress_messages do
  ActiveRecord::Schema.define(:version => 0) do
    create_table :jobs do |t|
      t.column :priority,           :integer, :default => 0
      t.column :status,             :string,  :limit => 20
      t.column :status_description, :string
      t.column :processable,        :text
      t.column :process_at,         :datetime
      t.column :processed_at,       :datetime
    end
    create_table :remote_updaters do |t|
      t.column :horse_id, :integer
    end
    create_table :fetchers do |t|
    end    
  end
end

class RemoteUpdater < ActiveRecord::Base
  def process!; end
end

JOB_FU_CONFIG_FILE = Pathname.new(__FILE__).dirname.join('fixtures', 'job_fu.yml').expand_path.to_s

Spec::Runner.configure do |config|
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures  = false
  config.include CustomMatchers
  config.mock_with :mocha
end
