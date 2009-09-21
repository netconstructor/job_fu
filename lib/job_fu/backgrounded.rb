module JobFu
  module Backgrounded
    class Handler
      def request(object, method, *args)
        opt = args.extract_options!
        priority, process_at = opt[:priority], opt[:at]
        priority ||= JobFu::Config['default_priority']
        Job.enqueue ProcessableMethod.new(object, method, *args), priority, process_at
      end      
    end    
  end
end