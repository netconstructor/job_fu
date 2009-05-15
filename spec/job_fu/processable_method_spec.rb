require File.dirname(__FILE__) + '/../spec_helper'

include JobFu

class BackgroundJob
  def converter(data)
  end
end

class Fetcher < ActiveRecord::Base
  def fetch_latest_data(*args)
  end
end


describe ProcessableMethod do  
  subject { ProcessableMethod.new(BackgroundJob.new, :method, "method_args") }
  specify { ProcessableMethod.included_modules.should include(Serialization) }  
  
  it { should respond_to(:process!) }
  it { should have_accessor(:object) }
  it { should have_accessor(:method_name) }
  it { should have_accessor(:args) }

  context "initialize" do
    before do
      @processable_method = ProcessableMethod.new(BackgroundJob.new, :converter, "method_args")      
    end
    
    specify { @processable_method.method_name.should == :converter }
    specify { @processable_method.args.should == ["method_args".to_yaml] }
        
  end
  
  context "method arguments" do
    
    it "should serialize method arguments" do
      ru = RemoteUpdater.create      
      @processable_method = ProcessableMethod.new(Fetcher.create, :fetch_latest_results, ru, RemoteUpdater)
      @processable_method.args.should include("AR:RemoteUpdater:#{ru.id}")
      @processable_method.args.should include("Class:RemoteUpdater")
    end
    
  end
  
  context "process" do
    before do
       @remote_updater = RemoteUpdater.create
       @processable_method = ProcessableMethod.new(Fetcher.create, :fetch_latest_results, @remote_updater)
     end
    it "should run fetch latest results after been serialized and unserialized" do
      Fetcher.any_instance.expects(:fetch_latest_results)
      str = YAML.dump(@processable_method)
      obj = YAML.load(str)
      obj.process!
    end
  end
  
end
