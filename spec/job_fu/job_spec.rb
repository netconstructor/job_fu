require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include JobFu

class DaemonMailer < Struct.new(:email, :subject, :body)
  def process!; end
end

class ProcessableClass
  def self.process!; end
end

module RSS
  class Fetcher < ActiveRecord::Base
    set_table_name :fetchers
    def process!; end
  end
end

describe Job do

  after(:each) do
    Job.delete_all
  end

  def new_daemon_mailer
    DaemonMailer.new('somebody@internet.com', 'Subject of message', 'Message body')
  end

  it "should create a new record" do
    lambda { Job.create }.should change { Job.count }.by(1)
  end

  it "should have default value of priority to 0" do
    Job.new.priority.should eql(0)
  end

  it "should set processable task" do
    @job = Job.create :processable => DaemonMailer.new
    @job.processable.class.should == DaemonMailer
  end

  it "should serialize processable task" do
    Job.create(:processable => DaemonMailer.new('somebody@internet.com', 'Subject of message', 'Message body'))
    Job.last.processable.email.should eql('somebody@internet.com')
  end

  it "should serialize class processable object" do
    @job = Job.new(:processable => ProcessableClass)
    @job.read_attribute(:processable).should eql("Class:ProcessableClass")
  end

  it "should unserialize class processable object" do
    @job = Job.create(:processable => ProcessableClass)
    Job.last.processable == ProcessableClass
  end

  it "should not serialize processable activerecord objects" do
    @remote_updater = RemoteUpdater.create
    @job = Job.new(:processable => @remote_updater)
    @job.read_attribute(:processable).should eql("AR:RemoteUpdater:#{@remote_updater.id}")
  end

  it "should unserialize processable activerecord objects" do
    @remote_updater = RemoteUpdater.create
    Job.create(:processable => @remote_updater)
    Job.last.processable.should == @remote_updater
  end

  it "should serialize and unserialize namespaced activerecord objects" do
    Job.create(:processable => RSS::Fetcher.create)
    Job.last.processable.class == RSS::Fetcher
  end

  it "should find the next job" do
    @next = Job.create(:processable => DaemonMailer.new)
    Job.create(:processable => RSS::Fetcher.create)
    Job.next.should == @next
  end

  it "should find the next job with priority in consideration" do
    Job.create(:processable => DaemonMailer.new, :priority => 1)
    @next = Job.create(:processable => DaemonMailer.new, :priority => 5)
    Job.create(:processable => DaemonMailer.new, :priority => 3)
    Job.next.should == @next
  end

  it "should mark in progress" do
    Job.create(:processable => DaemonMailer.new)
    lambda {
      Job.next
    }.should change { Job.last.status }.from(nil).to("in_progress")
  end

  it "should mark in progress unless status" do
    job = Job.create(:processable => DaemonMailer.new, :status => nil)
    lambda {
      job.process!
    }.should change { job.status }.from(nil).to("processed")
  end

  it "should execute process! for processable and mark as processed" do
    processable = DaemonMailer.new
    processable.expects(:process!).once.returns(true)
    job = Job.create(:processable => processable, :status => "in_progress")
    job.process!
    job.status.should eql("processed")
  end

  it "should mark as failure on exceptions" do
    job = Job.create(:processable => DaemonMailer.new, :status => "in_progress")
    job.processable.expects(:process!).once.raises
    job.process!
    job.status.should eql('failure')
  end

  it "should not delete on job failure" do
    job = Job.create(:processable => DaemonMailer.new, :status => "in_progress")
    job.processable.expects(:process!).once.raises
    lambda { job.process! }.should_not change { Job.count }
  end

  it "should be deleted after successfully processed job" do
    job = Job.create(:processable => DaemonMailer.new, :status => "in_progress")
    lambda {
      job.process!
    }.should change { Job.count }.by(-1)
  end

  it "should enqueue processable object" do
    lambda {
      Job.add new_daemon_mailer
    }.should change { Job.count }.by(1)
    Job.last.process!
  end

  it "should alias add to enqueue processable object" do
    lambda {
      Job.enqueue new_daemon_mailer
    }.should change { Job.count }.by(1)
    Job.last.process!
  end

  it "should process enqueued object" do
    DaemonMailer.any_instance.expects(:process!)
    Job.add new_daemon_mailer
    Job.last.process!
  end

  it "should not care if process at is not present" do
    Job.add ProcessableClass, 0
    Job.next.should_not be_nil
  end

  it "should not process jobs for the future" do
    Job.add ProcessableClass, 0, 1.minute.from_now
    Job.next.should be_nil
  end

  it "should process jobs when the future is past" do
    Job.add ProcessableClass, 0, 1.second.from_now
    Job.stubs(:time_now => 2.seconds.from_now)
    Job.next.should_not be_nil
  end

  it "should force process for all" do
    Job.add ProcessableClass, 0, 1.second.from_now
    Job.force_process_all!
  end

  it "should ignore if processable objects is deleted" do
    remote_updater = RemoteUpdater.create
    RemoteUpdater.delete(remote_updater.id)
    Job.add remote_updater
    n = Job.next
    n.process!
    n.status.should == 'failure'
  end
  
  it "should work off in the order they come in" do
    job1 = RemoteUpdater.create
    job2 = RemoteUpdater.create
    job3 = RemoteUpdater.create
    
    Job.add job1
    Job.add job2
    Job.add job3
    
    [job1, job2, job3].each do |j|
      Job.next.processable.should == j
    end
  end
  
  it "should not return jobs for other workers" do
    JobFu::Job.worker = "job-fu-worker"
    Job.add DaemonMailer.new, nil, nil, "some-other-worker"
    Job.next.should be_nil
  end
  
  it "should return jobs for the current worker or when no worker is set" do
    JobFu::Job.worker = "job-fu-worker"
    
    job1 = RemoteUpdater.create
    job2 = RemoteUpdater.create
    job3 = RemoteUpdater.create
    job4 = RemoteUpdater.create
    
    Job.add job1, nil, nil, "job-fu-worker"
    Job.add job2, nil, nil, "some-other-worker"
    Job.add job3, nil, nil, nil
    Job.add job4, nil, nil, ""
    
    Job.next_in_queue.map(&:processable).should == [job1, job3, job4]
  end

end
