module JobFu
  class ProcessableMethod
    include Serialization
    alias dump object_to_string
    alias load object_from_string
    
    attr_accessor :object, :method_name, :args
    
    def initialize(object, method_name, *args)
      @object = dump(object)
      @method_name = method_name
      @args = args.map {|arg| dump(arg) }
    end
    
    def process!
      load(@object).send(method_name, *args.map{|arg| load(arg) })
    end    
  end
end
