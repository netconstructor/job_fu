module JobFu
  module Backgrounded
    class Handler
      def request(object, method)
        Job.enqueue ProcessableMethod.new(object, method)
      end      
    end    
  end
end