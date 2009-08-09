class JobFuGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.file 'job_ctl', 'script/job_ctl'
      m.file 'job_fu', 'script/job_fu'
      m.template 'job_fu.yml.erb', 'config/job_fu.yml'
      m.migration_template 'create_jobs.rb', 'db/migrate', :migration_file_name => 'create_jobs'
    end
  end
  
  def app_name
    Rails.root.basename
  end
  
end