module JobFu
  module AsynchInvokeMethod
    
    def method_missing(name, *args)
      return Job.add(ProcessableMethod.new(self, $1, *args)) if name.to_s =~ /^asynch?_(\S+)$/
      super
    end
    
  end
end

