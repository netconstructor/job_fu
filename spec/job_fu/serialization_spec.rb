require File.dirname(__FILE__) + '/../spec_helper'
require 'actionmailer'

include JobFu

class Serializer
  include Serialization
end

class Mailer < ActionMailer::Base
end

describe Serializer do
  before { @remote_updater = RemoteUpdater.create }
  
  it { should serialize(Mailer).to('Class:Mailer') }
  it { should serialize(RemoteUpdater).to('Class:RemoteUpdater') }
  it { should unserialize('Class:RemoteUpdater').to(RemoteUpdater) }
  
  it { should serialize(@remote_updater).to("AR:RemoteUpdater:#{@remote_updater.id}") }
  it { should unserialize("AR:RemoteUpdater:#{@remote_updater.id}").to(@remote_updater) }
end
