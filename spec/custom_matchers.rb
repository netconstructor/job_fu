module CustomMatchers

  class SerializeMatcher

    def initialize(object_to_serialize)
      @object_to_serialize = object_to_serialize
    end

    def matches?(serializer)
      @serializer = serializer
      @actual_string_representation = serializer.object_to_string(@object_to_serialize)
      @actual_string_representation == @desired_string_representation
    end

    def to(desired_string_representation)
      @desired_string_representation = desired_string_representation
      self
    end

    def failure_message_for_should
      "expected #{@object_to_serialize.inspect} to serialize as #{@desired_string_representation.inspect}, but it returned #{@actual_string_representation}"
    end

    def description
      "should serialize #{@object_to_serialize.inspect} to #{@desired_string_representation}"
    end

  end

  def serialize(expected)
    SerializeMatcher.new(expected)
  end
  
  class UnSerializeMatcher

    def initialize(string_representation)
      @string_representation = string_representation
    end

    def matches?(serializer)
      @serializer = serializer
      @actual_object = serializer.object_from_string(@string_representation)
      @actual_object == @desired_object
    end

    def to(desired_object)
      @desired_object = desired_object
      self
    end

    def failure_message_for_should
      "expected #{@string_representation.inspect} to unserialize as #{@desired_object.inspect}, but it returned #{@actual_object}"
    end

    def description
      "should unserialize #{@string_representation.inspect} to #{@desired_object}"
    end

  end

  def unserialize(expected)
    UnSerializeMatcher.new(expected)
  end 
  
  Spec::Matchers.define :have_accessor do |attr_name|
    match do |receiver|
      receiver.respond_to?(:"#{attr_name}") && receiver.respond_to?(:"#{attr_name}=")
    end
  end
  

end
