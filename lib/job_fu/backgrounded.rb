module JobFu
  module Backgrounded
    class Handler

      def clear_queue!
        JobFu::Job.delete_all
      end
      
      def force_process_all!
        JobFu::Job.force_process_all!
      end

      def request(object, method, *args)
        opt = args.extract_options!
        priority, process_at, worker = opt.values_at(:priority, :at, :worker)
        Job.enqueue ProcessableMethod.new(object, method, *args), priority, process_at, worker
      end      
    end    
  end
end
