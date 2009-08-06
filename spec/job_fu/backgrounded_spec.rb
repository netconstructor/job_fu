require File.dirname(__FILE__) + '/../spec_helper'

class MyBackgrounded
  cattr_accessor :count
  self.count = 0
  def do_stuff
    self.count += 1
  end
end

describe JobFu::Backgrounded::Handler do
  
  it "should add job to queue" do
    expect {
      described_class.new.request(MyBackgrounded.new, :do_stuff)
    }.to change { JobFu::Job.count }
  end
  
end
