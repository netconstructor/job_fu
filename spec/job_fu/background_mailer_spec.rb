require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'actionmailer'

ActionMailer::Base.delivery_method = :test

class AppMailer <  ActionMailer::Base
  include JobFu::BackgroundMailer

  def signup_notification(user)
    recipients user.email
    from "do-not-replay@app_name.com"
    body "Body of email message"
  end
end

class User < Struct.new(:email)
end

describe JobFu::BackgroundMailer do
  before(:each) do
    @user = User.new('somebody@somewhere.com')
    ActionMailer::Base.deliveries.clear
  end

  it "should enqueue the mail" do
    lambda {
      AppMailer.asynch_deliver_signup_notification(@user)
    }.should change { JobFu::Job.count }.by(1)
  end
  
  it "should not invoke deliver directly" do
    AppMailer.expects(:deliver_signup_notification).never
    AppMailer.asynch_deliver_signup_notification(@user)
  end
  
  it "should deliver mail from the job queue" do
    AppMailer.asynch_deliver_signup_notification(@user)
    lambda {
      JobFu::Job.last.process!
    }.should change { ActionMailer::Base.deliveries.size }.by(1)
  end
end
