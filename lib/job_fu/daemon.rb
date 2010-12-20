require 'rubygems'
require 'yaml'
gem 'FiXato-daemons', '= 1.0.10.2'
require 'daemons'
require File.dirname(__FILE__) + '/config'

module JobFu

  class Daemon
    attr_reader :args
    attr_reader :config

    def initialize(options)
      @config = options[:config] ||= JobFu::Config.new
      @args = options[:ARGV]
    end

    def daemonize
      if args.size > 1
        setup(worker_by!(args.pop))
      else
        config['workers'].each { |worker| setup(worker) }
      end
    end
   
    def setup(worker)
      process_name = "#{config['app_name']}-#{worker['name']}"
      Daemons.run_proc(process_name, :dir => Pathname.new(RAILS_ROOT).join('tmp', 'pids').to_s, :dir_mode => :normal, :force_kill_wait => @config['force_kill_wait'], :ARGV => [@args.first]) do
        start(worker)
      end
    end
    
    def worker_by!(name)
      worker = config['workers'].detect { |worker| worker['name'] == name }
      raise "No worker named '#{name}' available" unless worker
      worker
    end
   
    def start(options = {})
      Dir.chdir(RAILS_ROOT)

      require Pathname.new(RAILS_ROOT).join('config', 'environment')

      sleep_time = options['sleep_time'] || 5
      JobFu::Job.worker = options['name']
      
      Rails.logger.auto_flushing = true
      Rails.logger.info "=> Booting JobFu daemon in '#{Rails.env}' environment"
      Rails.logger.info "** JobFu Worker #{JobFu::Job.worker.inspect}"

      $running = true
      Signal.trap("TERM") do
        $running = false
      end

      while($running) do
        [ActiveRecord::Base].each do |klass|
          klass.connection.verify!(15)
        end

        next_job = JobFu::Job.next
        unless next_job.blank?
          next_job.process!
        else
          sleep sleep_time
        end
      end

    end

  end
end
