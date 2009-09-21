require 'forwardable'
require 'pathname'

module JobFu
  class Config
    extend Forwardable
    attr_reader :config
    def_delegators :@config, :[]

    def environment
      ENV['RAILS_ENV'] || 'production'
    end

    def initialize(filename = self.class.config_file_path)
      @config = YAML.load_file(filename)[environment]
    end

    def self.config_file_path
      Pathname.new(RAILS_ROOT).join('config', 'job_fu.yml')
    end

    class << self

      attr_reader :config
      def [](*args)
        unless @config
          @config ||= JobFu::Config.new
        end
        @config[*args]
      end
    end
    
  end
end
