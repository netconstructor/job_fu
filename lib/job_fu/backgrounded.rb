module JobFu
  module Backgrounded
    class Handler
      def request(object, method, *args)
        Job.enqueue ProcessableMethod.new(object, method, *args)
      end      
    end    
  end
end