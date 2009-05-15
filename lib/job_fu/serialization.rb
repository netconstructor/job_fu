module JobFu
  module Serialization
    
    def object_to_string(job)
      case job
      when Class
        "Class:#{job}"
      when ActiveRecord::Base
        "AR:#{job.class}:#{job.id}"
      else
        job.to_yaml
      end
    end

    def object_from_string(str)
      case str
      when /^--- \!ruby\/\w+:(\S+)/        
        load_yaml(str, $1)
      when /^Class:(.*?)$/
        eval("::#{$1}")
      when /^AR:(.*?):(\d+)$/
        load_active_record_object($1, $2)
      else
        load_yaml(str)
      end
    end
    
    def load_yaml(str, class_name = nil)
      eval("::#{class_name}") if class_name.present? # ActiveSupport autoload
      YAML.load(str)
    end

    def load_active_record_object(class_name, id)
      klass = eval("::#{class_name}")
      klass.find(id)
    end    
        
  end
end