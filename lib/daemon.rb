#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")

Rails.logger.auto_flushing = true
Rails.logger.info "=> Booting JobFu daemon in '#{Rails.env}' environment"

$running = true
Signal.trap("TERM") do
  $running = false
end

while($running) do
  [ActiveRecord::Base].each do |klass|
    klass.connection.verify!(15)
  end
  
  next_job = JobFu::Job.next
  unless next_job.blank?
    next_job.process!
  else
    sleep 5
  end
end
