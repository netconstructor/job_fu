require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe JobFu::Config do
  before do
    described_class.stubs(:config_file_path).returns(Pathname.new(__FILE__).join('..', '..', 'fixtures', 'job_fu.yml'))
  end
  
  it "loads workers" do
    described_class['workers'].should have(1).workers
  end
    
end
