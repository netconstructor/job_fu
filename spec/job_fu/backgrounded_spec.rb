require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class MyBackgrounded
  cattr_accessor :count
  self.count = 0
  def do_stuff
    self.count += 1
  end
end

describe JobFu::Backgrounded::Handler do
  
  before do
    JobFu::Config.stubs(:config_file_path).returns(JOB_FU_CONFIG_FILE)
  end

  it "adds job to queue" do
    expect {
      described_class.new.request(MyBackgrounded.new, :do_stuff)
    }.to change { JobFu::Job.count }
  end

  it "adds with priority" do
    described_class.new.request(MyBackgrounded.new, :do_stuff, :priority => 5)
    JobFu::Job.last.priority.should == 5
  end

  it "adds with run at" do
    process_at = 1.minute.from_now
    described_class.new.request(MyBackgrounded.new, :do_stuff, :at => process_at)
    JobFu::Job.last.process_at.should be_close(process_at, 1)
  end
  
  it "adds with worker" do
    process_at = 1.minute.from_now
    described_class.new.request(MyBackgrounded.new, :do_stuff, :worker => "job-fu-worker")
    JobFu::Job.last.worker.should == "job-fu-worker"
  end

end
