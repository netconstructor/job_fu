namespace :job_fu do
  desc "Start job fu worker"
  task :work => :environment do
    loop do
      puts "Checking queue for work..."
      JobFu::Job.force_process_all!
      sleep 1
    end
  end
end

