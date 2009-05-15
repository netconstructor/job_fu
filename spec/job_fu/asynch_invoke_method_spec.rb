require File.dirname(__FILE__) + '/../spec_helper'


class Worker
  include JobFu::AsynchInvokeMethod
  
  def something_heavy
  end
end

describe RemoteUpdater do
  it "should add remote updater to the job queue" do
    worker = Worker.new
    lambda {
      worker.asynch_something_heavy
    }.should change { JobFu::Job.count }.by(1)
  end
  
  it "should save the full class name included module" do
    worker = Worker.new
    job = worker.async_something_heavy
    job.read_attribute(:processable).should match(/JobFu::ProcessableMethod/)
  end
end
