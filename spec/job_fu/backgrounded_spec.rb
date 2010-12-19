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

  it "should add job to queue" do
    expect {
      described_class.new.request(MyBackgrounded.new, :do_stuff)
    }.to change { JobFu::Job.count }
  end

  it "should add with priority" do
    described_class.new.request(MyBackgrounded.new, :do_stuff, :priority => 5)
    JobFu::Job.last.priority.should == 5
  end

  it "should add with run at" do
    process_at = 1.minute.from_now
    described_class.new.request(MyBackgrounded.new, :do_stuff, :at => process_at)
    JobFu::Job.last.process_at.should be_close(process_at, 1)
  end

  it "should set default priority" do
    described_class.new.request(MyBackgrounded.new, :do_stuff)
    JobFu::Job.last.priority.should == 0
  end

end
