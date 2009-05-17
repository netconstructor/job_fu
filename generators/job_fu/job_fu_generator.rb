class JobFuGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.file 'job_ctl', 'script/job_ctl'
      m.migration_template 'create_jobs.rb', 'db/migrate', :migration_file_name => 'create_jobs'
    end
  end
  
end